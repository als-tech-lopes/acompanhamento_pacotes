create extension if not exists pgcrypto;

create table if not exists public.importacoes (
  id uuid primary key default gen_random_uuid(), nome_arquivo text not null,
  storage_original_path text not null, storage_parquet_path text,
  hash_arquivo text not null, tamanho_bytes bigint not null, versao_layout text,
  total_linhas integer default 0, linhas_validas integer default 0,
  linhas_erro integer default 0, linhas_duplicadas integer default 0,
  status text not null default 'recebida', usuario_importacao uuid,
  iniciada_em timestamptz not null default now(), concluida_em timestamptz,
  metadados jsonb not null default '{}'::jsonb
);

create table if not exists public.bronze_entregas_raw (
  id bigint generated always as identity primary key,
  importacao_id uuid not null references public.importacoes(id),
  numero_linha_origem integer not null, payload_original_json jsonb not null,
  cabecalhos_originais jsonb not null, nome_arquivo_origem text not null,
  data_importacao timestamptz not null default now(), usuario_importacao uuid,
  hash_registro text not null, classificacao_validacao text default 'pendente',
  erros_validacao jsonb not null default '[]'::jsonb, created_at timestamptz not null default now(),
  unique(importacao_id, numero_linha_origem)
);
create index if not exists idx_bronze_importacao on public.bronze_entregas_raw(importacao_id);
create index if not exists idx_bronze_hash on public.bronze_entregas_raw(hash_registro);

