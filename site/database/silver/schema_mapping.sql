create table if not exists public.schema_mapping (
  id uuid primary key default gen_random_uuid(), versao_layout text not null,
  nome_coluna_original text not null, posicao_coluna integer,
  nome_coluna_tecnica text not null, nome_exibicao text not null,
  tipo_dado text not null default 'text', obrigatoria boolean not null default false,
  ativa boolean not null default true, descricao text, transformacao_aplicada text,
  contexto_etapa text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(versao_layout, nome_coluna_original, posicao_coluna)
);
create index if not exists idx_mapping_lookup on public.schema_mapping(versao_layout, ativa);

