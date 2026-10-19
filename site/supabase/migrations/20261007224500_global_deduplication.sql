create table if not exists public.arquivos_processados (
  hash_arquivo text primary key,
  importacao_id uuid not null references public.importacoes(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.registros_processados (
  hash_registro text primary key,
  importacao_id uuid not null references public.importacoes(id) on delete cascade,
  created_at timestamptz not null default now()
);

insert into public.arquivos_processados (hash_arquivo, importacao_id)
select distinct on (hash_arquivo) hash_arquivo, id
from public.importacoes
where hash_arquivo is not null and status = 'concluida'
order by hash_arquivo, concluida_em, id
on conflict (hash_arquivo) do nothing;

insert into public.registros_processados (hash_registro, importacao_id)
select distinct on (hash_registro) hash_registro, importacao_id
from public.bronze_entregas_raw
order by hash_registro, id
on conflict (hash_registro) do nothing;

create or replace view public.vw_entregas_atuais as
select distinct on (coalesce(nullif(numero_waybill, ''), 'id:' || id::text)) *
from public.silver_entregas
where not eh_duplicado
order by coalesce(nullif(numero_waybill, ''), 'id:' || id::text), coalesce(data_ultimo_rastreio, updated_at) desc, id desc;

create or replace view public.vw_resumo_operacional as
with base as (
  select * from public.vw_entregas_atuais
), totais as (
  select
    count(*)::int as total,
    count(*) filter (where lower(coalesce(status_pacote,'')) in ('pedido entregue','entregue','assinado'))::int as entregues,
    count(*) filter (where lower(coalesce(status_pacote,'')) in ('pedido entregue','entregue','assinado') and status_sla = 'no_prazo')::int as entregues_no_prazo,
    count(*) filter (where lower(coalesce(status_pacote,'')) not in ('pedido entregue','entregue','assinado','devolvido','cancelado'))::int as backlog,
    count(*) filter (where coalesce(dias_atraso,0) > 0)::int as atrasadas,
    count(*) filter (where data_hora_entrega_ponto is not null)::int as last_mile_total,
    count(*) filter (where data_hora_entrega_ponto is not null and data_hora_primeira_entrega <= prazo_calculado)::int as last_mile_no_prazo,
    count(*) filter (where horas_sem_movimentacao > 24 and lower(coalesce(status_pacote,'')) not in ('pedido entregue','entregue','assinado','devolvido','cancelado'))::int as sem_movimentacao,
    count(*) filter (where horas_sem_movimentacao > 72 and lower(coalesce(status_pacote,'')) not in ('pedido entregue','entregue','assinado','devolvido','cancelado'))::int as sem_movimentacao_72h
  from base
), regioes as (
  select jsonb_agg(jsonb_build_object('nome', regiao, 'total', total, 'sla', round(100.0 * no_prazo / nullif(total,0), 1)) order by total desc) as itens
  from (select coalesce(nullif(regiao,''),'Não informado') as regiao, count(*)::int as total, count(*) filter (where status_sla = 'no_prazo')::int as no_prazo from base group by 1) r
), status as (
  select jsonb_agg(jsonb_build_object('nome', nome, 'total', total) order by total desc) as itens
  from (select coalesce(nullif(status_pacote,''),'Não informado') as nome, count(*)::int as total from base group by 1) s
)
select t.total, t.entregues,
  coalesce(round(100.0 * t.entregues_no_prazo / nullif(t.entregues,0), 1), 0) as sla_cadeia,
  t.backlog, t.atrasadas,
  coalesce(round(100.0 * t.last_mile_no_prazo / nullif(t.last_mile_total,0), 1), 0) as sla_last_mile,
  t.last_mile_total, t.sem_movimentacao, t.sem_movimentacao_72h,
  coalesce(r.itens, '[]'::jsonb) as regioes,
  coalesce(s.itens, '[]'::jsonb) as status,
  now() as atualizado_em
from totais t cross join regioes r cross join status s;

alter table public.arquivos_processados enable row level security;
alter table public.registros_processados enable row level security;
