create table if not exists public.silver_entregas (
  id bigint generated always as identity primary key,
  bronze_id bigint not null references public.bronze_entregas_raw(id),
  importacao_id uuid not null references public.importacoes(id),
  numero_waybill text, numero_pedido_anjun text, numero_ordem_escaneamento text,
  tipo_pacote text, status_pacote text, tag text, tipo_pedido text,
  nome_cliente text, nome_cliente_merchant text,
  data_ultimo_rastreio timestamptz, ultimo_rastreio text, ultimo_ponto_rastreio text,
  motivo_ocorrencia text, uf_destinatario char(2), cidade_destinatario text,
  bairro_destinatario text, cep_destinatario text, regiao text, uf_origem char(2),
  cidade_remetente text, ponto_pre_entrega text, ponto_entrada text,
  uf_ponto_entrada char(2), ponto_entrega text, entregador text,
  tipo_coleta text, tipo_assinatura text, data_criacao_pedido timestamptz,
  data_saida_armazem_cliente timestamptz, data_coleta_lm timestamptz,
  data_entrada_centro_nivel_01 timestamptz, data_saida_centro_nivel_01 timestamptz,
  data_entrada_centro_nivel_02 timestamptz, data_saida_centro_nivel_02 timestamptz,
  data_entrada_centro_nivel_03 timestamptz, data_saida_centro_nivel_03 timestamptz,
  data_hora_entrega_ponto timestamptz, data_hora_primeira_entrega timestamptz,
  tempo_despacho_ponto_horas numeric, tempo_transito_despacho_horas numeric,
  tempo_total_assinatura_horas numeric, dias_prazo_requisitados_cliente integer,
  horario_limite_entrega time, prazo_calculado timestamptz, duracao_atraso_horas numeric,
  dias_atraso integer, horas_sem_movimentacao numeric, status_sla text,
  eh_duplicado boolean not null default false, possui_erro boolean not null default false,
  erros_transformacao jsonb not null default '[]'::jsonb,
  valores_originais_criticos jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists uq_silver_origem on public.silver_entregas(bronze_id);
create index if not exists idx_silver_waybill on public.silver_entregas(numero_waybill);
create index if not exists idx_silver_pedido on public.silver_entregas(numero_pedido_anjun);
create index if not exists idx_silver_status on public.silver_entregas(status_pacote);
create index if not exists idx_silver_ultimo_rastreio on public.silver_entregas(data_ultimo_rastreio);
create index if not exists idx_silver_criacao on public.silver_entregas(data_criacao_pedido);
create index if not exists idx_silver_cliente on public.silver_entregas(nome_cliente);
create index if not exists idx_silver_destino on public.silver_entregas(regiao, uf_destinatario, cidade_destinatario);
create index if not exists idx_silver_pontos on public.silver_entregas(ponto_entrada, ponto_entrega);
create index if not exists idx_silver_importacao on public.silver_entregas(importacao_id);

