-- Harden local upload authorization and improve dashboard performance.
drop policy if exists "local_anon_insert_importacoes" on storage.objects;

create index if not exists idx_silver_current_waybill
on public.silver_entregas (
  numero_waybill,
  data_ultimo_rastreio desc nulls last,
  updated_at desc,
  id desc
)
where not eh_duplicado;

create or replace view public.vw_resumo_operacional as
with base as (
  select
    current_rows.*,
    case
      when data_ultimo_rastreio is null then null
      else greatest(0, extract(epoch from (now() - data_ultimo_rastreio)) / 3600)
    end as horas_sem_movimentacao_atual
  from public.vw_entregas_atuais current_rows
), totais as (
  select
    count(*)::int as total,
    count(*) filter (where lower(coalesce(status_pacote,'')) in ('pedido entregue','entregue','assinado'))::int as entregues,
    count(*) filter (where lower(coalesce(status_pacote,'')) in ('pedido entregue','entregue','assinado') and status_sla = 'no_prazo')::int as entregues_no_prazo,
    count(*) filter (where lower(coalesce(status_pacote,'')) not in ('pedido entregue','entregue','assinado','devolvido','cancelado'))::int as backlog,
    count(*) filter (where coalesce(dias_atraso,0) > 0)::int as atrasadas,
    count(*) filter (where data_hora_entrega_ponto is not null)::int as last_mile_total,
    count(*) filter (where data_hora_entrega_ponto is not null and data_hora_primeira_entrega <= prazo_calculado)::int as last_mile_no_prazo,
    count(*) filter (where horas_sem_movimentacao_atual > 24 and lower(coalesce(status_pacote,'')) not in ('pedido entregue','entregue','assinado','devolvido','cancelado'))::int as sem_movimentacao,
    count(*) filter (where horas_sem_movimentacao_atual > 72 and lower(coalesce(status_pacote,'')) not in ('pedido entregue','entregue','assinado','devolvido','cancelado'))::int as sem_movimentacao_72h
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
