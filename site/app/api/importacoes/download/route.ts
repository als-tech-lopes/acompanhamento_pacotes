import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

export async function GET(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const url = new URL(request.url);
    const id = url.searchParams.get("id");
    const kind = url.searchParams.get("tipo") === "parquet" ? "parquet" : "original";
    if (!id) return Response.json({ error: "Importação inválida." }, { status: 400 });
    const admin = getSupabaseAdmin();
    const { data: record, error: recordError } = await admin.from("importacoes").select("storage_original_path,storage_parquet_path").eq("id", id).single();
    if (recordError) throw recordError;
    const path = kind === "parquet" ? record.storage_parquet_path : record.storage_original_path;
    if (!path) return Response.json({ error: "Arquivo ainda não disponível." }, { status: 404 });
    const { data, error } = await admin.storage.from(kind === "parquet" ? "parquet" : "importacoes").createSignedUrl(path, 60, { download: true });
    if (error) throw error;
    return Response.redirect(data.signedUrl, 302);
  } catch (error) {
    console.error("Falha ao preparar download", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao preparar download." }, { status: 500 });
  }
}
