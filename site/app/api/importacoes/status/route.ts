import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

export async function GET(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const id = new URL(request.url).searchParams.get("id");
    if (!id) return Response.json({ error: "Importação inválida." }, { status: 400 });
    const admin = getSupabaseAdmin();
    const { data, error } = await admin.from("importacoes").select("id,nome_arquivo,tamanho_bytes,status,etapa,progresso,total_linhas,total_colunas,colunas_mapeadas,colunas_nao_mapeadas,linhas_validas,linhas_erro,linhas_duplicadas,linhas_processadas,storage_parquet_path,mensagem_erro,metadados").eq("id", id).single();
    if (error) throw error;
    return Response.json(data);
  } catch (error) {
    console.error("Falha ao consultar importação", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao consultar importação." }, { status: 500 });
  }
}
