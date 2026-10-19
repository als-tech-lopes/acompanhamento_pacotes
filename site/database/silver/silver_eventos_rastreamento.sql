create table if not exists public.silver_eventos_rastreamento (
  id bigint generated always as identity primary key,
  entrega_id bigint not null references public.silver_entregas(id),
  bronze_id bigint references public.bronze_entregas_raw(id),
  etapa text not null, codigo_evento text, descricao_evento text,
  ponto text, ocorrido_em timestamptz, sequencia integer,
  payload_original jsonb, created_at timestamptz not null default now()
);
create index if not exists idx_eventos_entrega_data on public.silver_eventos_rastreamento(entrega_id, ocorrido_em);

