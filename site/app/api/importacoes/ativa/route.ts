import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

const activeStatuses = ["aguardando_upload", "aguardando_processamento", "processando"];

export async function GET(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const admin = getSupabaseAdmin();
    const id = new URL(request.url).searchParams.get("id");
    const fields = "id,nome_arquivo,status,etapa,progresso,total_linhas,linhas_validas,linhas_erro,linhas_duplicadas,linhas_processadas,mensagem_erro,iniciada_em,concluida_em";
    const query = admin.from("importacoes").select(fields);
    const { data, error } = id
      ? await query.eq("id", id).single()
      : await query.in("status", activeStatuses).order("iniciada_em", { ascending: false }).limit(1).maybeSingle();
    if (error) throw error;
    return Response.json({ importacao: data ?? null });
  } catch (error) {
    console.error("Falha ao localizar importação ativa", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao localizar importação ativa." }, { status: 500 });
  }
}
