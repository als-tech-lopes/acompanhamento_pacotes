# Pipeline local de importações

O fluxo utiliza o Supabase local para PostgreSQL e Storage e um worker Python separado para processar arquivos sem carregar o conteúdo inteiro no navegador.

## Componentes

- O navegador envia o arquivo diretamente ao bucket privado `importacoes` usando upload TUS resumível.
- As APIs em `app/api/importacoes` criam e acompanham a carga, mas nunca recebem os bytes do arquivo.
- O worker em `worker/` busca cargas pendentes, lê XLSX em modo `read_only`, processa lotes de 500 linhas, grava Bronze e Silver e gera Parquet incrementalmente.
- O original e o Parquet ficam nos buckets privados `importacoes` e `parquet`.
- A migration oficial está em `supabase/migrations`. Os arquivos em `database/` documentam as partes da arquitetura.

## Primeira execução

```powershell
cd C:\Users\ArthurLopes\projetos\anjun_logistica\site
npm.cmd install
npm.cmd run supabase:start
npm.cmd run db:migrate
```

Copie os valores retornados por `npm.cmd run supabase:status` para `.env.local`, seguindo `.env.example`.

Inicie o worker:

```powershell
npm.cmd run worker:up
npm.cmd run worker:logs
```

Em outro terminal, inicie a aplicação:

```powershell
npm.cmd run dev
```

## Teste automatizado

Com a aplicação, o Supabase e o worker ativos:

```powershell
npm.cmd run test:import
```

O teste envia `relatorio_amostra.xlsx`, aguarda o processamento e valida 88 linhas, 87 colunas, Bronze, Silver e o Parquet. Execute-o em uma base limpa ou com um arquivo inédito: uma carga duplicada agora faz o teste falhar, pois não revalida as transformações.

## Consultas de conferência

```sql
select id, nome_arquivo, status, progresso, total_linhas
from public.importacoes
order by iniciada_em desc;

select importacao_id, count(*)
from public.bronze_entregas_raw
group by importacao_id;

select importacao_id, count(*)
from public.silver_entregas
group by importacao_id;
```

Para encerrar somente o worker:

```powershell
npm.cmd run worker:down
```

Para encerrar o Supabase preservando os dados:

```powershell
npx.cmd supabase stop
```
