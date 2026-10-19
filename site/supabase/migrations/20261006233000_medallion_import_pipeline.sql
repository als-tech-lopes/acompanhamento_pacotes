create extension if not exists pgcrypto;

create table if not exists public.importacoes (
  id uuid primary key default gen_random_uuid(),
  nome_arquivo text not null,
  storage_original_path text not null,
  storage_parquet_path text,
  hash_arquivo text,
  tamanho_bytes bigint not null,
  versao_layout text,
  total_linhas integer not null default 0,
  total_colunas integer not null default 0,
  colunas_mapeadas integer not null default 0,
  colunas_nao_mapeadas integer not null default 0,
  linhas_validas integer not null default 0,
  linhas_erro integer not null default 0,
  linhas_duplicadas integer not null default 0,
  linhas_processadas integer not null default 0,
  progresso integer not null default 0 check (progresso between 0 and 100),
  etapa text not null default 'upload',
  status text not null default 'aguardando_upload',
  mensagem_erro text,
  usuario_importacao uuid,
  iniciada_em timestamptz not null default now(),
  concluida_em timestamptz,
  metadados jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bronze_entregas_raw (
  id bigint generated always as identity primary key,
  importacao_id uuid not null references public.importacoes(id) on delete cascade,
  numero_linha_origem integer not null,
  payload_original_json jsonb not null,
  cabecalhos_originais jsonb not null,
  nome_arquivo_origem text not null,
  data_importacao timestamptz not null default now(),
  usuario_importacao uuid,
  hash_registro text not null,
  classificacao_validacao text not null default 'valido',
  erros_validacao jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  unique(importacao_id, numero_linha_origem)
);

create table if not exists public.schema_mapping (
  id uuid primary key default gen_random_uuid(), versao_layout text not null,
  nome_coluna_original text not null, posicao_coluna integer,
  nome_coluna_tecnica text not null, nome_exibicao text not null,
  tipo_dado text not null default 'text', obrigatoria boolean not null default false,
  ativa boolean not null default true, descricao text, transformacao_aplicada text,
  contexto_etapa text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(versao_layout, nome_coluna_original, posicao_coluna)
);

create table if not exists public.silver_entregas (
  id bigint generated always as identity primary key,
  bronze_id bigint not null references public.bronze_entregas_raw(id) on delete cascade,
  importacao_id uuid not null references public.importacoes(id) on delete cascade,
  numero_waybill text, numero_ordem_escaneamento text, numero_pedido_anjun text,
  tipo_pacote text, status_pacote text, tag text, tipo_pedido text,
  nome_cliente text, nome_cliente_merchant text,
  data_ultimo_rastreio timestamptz, ultimo_rastreio text, ultimo_ponto_rastreio text,
  motivo_ocorrencia text, uf_destinatario text, cidade_destinatario text,
  bairro_destinatario text, rua_destinatario text, cep_destinatario text,
  regiao text, uf_origem text, cidade_remetente text,
  ponto_pre_entrega text, ponto_entrada text, uf_ponto_entrada text,
  ponto_entrega text, entregador text, tipo_coleta text, tipo_assinatura text,
  data_criacao_pedido timestamptz, data_saida_armazem_cliente timestamptz,
  data_coleta_lm timestamptz, data_hora_entrega_ponto timestamptz,
  data_hora_primeira_entrega timestamptz, prazo_calculado timestamptz,
  duracao_atraso_horas numeric, dias_atraso integer,
  horas_sem_movimentacao numeric, status_sla text,
  eh_duplicado boolean not null default false,
  possui_erro boolean not null default false,
  erros_transformacao jsonb not null default '[]'::jsonb,
  valores_originais_criticos jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(bronze_id)
);

create index if not exists idx_bronze_importacao on public.bronze_entregas_raw(importacao_id);
create index if not exists idx_bronze_hash on public.bronze_entregas_raw(hash_registro);
create index if not exists idx_silver_waybill on public.silver_entregas(numero_waybill);
create index if not exists idx_silver_pedido on public.silver_entregas(numero_pedido_anjun);
create index if not exists idx_silver_status on public.silver_entregas(status_pacote);
create index if not exists idx_silver_ultimo_rastreio on public.silver_entregas(data_ultimo_rastreio);
create index if not exists idx_silver_criacao on public.silver_entregas(data_criacao_pedido);
create index if not exists idx_silver_cliente on public.silver_entregas(nome_cliente);
create index if not exists idx_silver_destino on public.silver_entregas(regiao, uf_destinatario, cidade_destinatario);
create index if not exists idx_silver_pontos on public.silver_entregas(ponto_entrada, ponto_entrega);
create index if not exists idx_silver_importacao on public.silver_entregas(importacao_id);

create or replace view public.vw_sla_cadeia as
select *, status_sla = 'no_prazo' as entregue_no_prazo from public.silver_entregas
where status_pacote in ('Pedido entregue','entregue','assinado') and not eh_duplicado;

create or replace view public.vw_backlog as
select *, case when coalesce(dias_atraso,0) <= 1 then 'Até 1 dia' when dias_atraso <= 3 then '2 a 3 dias'
when dias_atraso <= 7 then '4 a 7 dias' else 'Mais de 7 dias' end as faixa_aging
from public.silver_entregas where coalesce(status_pacote,'') not in ('Pedido entregue','entregue','assinado','devolvido','cancelado') and not eh_duplicado;

create or replace view public.vw_sla_last_mile as
select *, case when data_hora_primeira_entrega <= prazo_calculado then 'no_prazo' else 'fora_prazo' end as sla_last_mile
from public.silver_entregas where data_hora_entrega_ponto is not null and not eh_duplicado;

create or replace view public.vw_sem_movimentacao as
select *, case when horas_sem_movimentacao > 168 then 'Mais de 7 dias' when horas_sem_movimentacao > 96 then 'Mais de 96 horas'
when horas_sem_movimentacao > 72 then 'Mais de 72 horas' when horas_sem_movimentacao > 48 then 'Mais de 48 horas' else 'Mais de 24 horas' end as faixa_sem_movimentacao
from public.silver_entregas where coalesce(status_pacote,'') not in ('Pedido entregue','entregue','assinado','devolvido','cancelado') and horas_sem_movimentacao > 24 and not eh_duplicado;

insert into storage.buckets (id, name, public, file_size_limit)
values ('importacoes', 'importacoes', false, 1073741824), ('parquet', 'parquet', false, 1073741824)
on conflict (id) do update set file_size_limit = excluded.file_size_limit;

alter table public.importacoes enable row level security;
alter table public.bronze_entregas_raw enable row level security;
alter table public.silver_entregas enable row level security;

