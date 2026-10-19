import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function POST(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const { id } = await request.json() as { id?: string };
    if (!id || !uuidPattern.test(id)) return Response.json({ error: "Importação inválida." }, { status: 400 });
    const admin = getSupabaseAdmin();
    const { data: record, error: recordError } = await admin.from("importacoes").select("id,status,storage_original_path").eq("id", id).maybeSingle();
    if (recordError) throw recordError;
    if (!record) return Response.json({ error: "Importação não encontrada." }, { status: 404 });
    if (record.status !== "aguardando_upload") return Response.json({ error: "Importação não está aguardando upload." }, { status: 409 });

    const slash = record.storage_original_path.lastIndexOf("/");
    const folder = record.storage_original_path.slice(0, slash);
    const fileName = record.storage_original_path.slice(slash + 1);
    const { data: objects, error: storageError } = await admin.storage.from("importacoes").list(folder, { search: fileName, limit: 1 });
    if (storageError) throw storageError;
    if (!objects?.some((object) => object.name === fileName)) return Response.json({ error: "Upload ainda não foi concluído." }, { status: 409 });

    const { data, error } = await admin.from("importacoes").update({ status: "aguardando_processamento", etapa: "fila", progresso: 5, updated_at: new Date().toISOString() }).eq("id", id).eq("status", "aguardando_upload").select("id,status").maybeSingle();
    if (error) throw error;
    if (!data) return Response.json({ error: "A importação mudou de estado; atualize a página." }, { status: 409 });
    return Response.json(data);
  } catch (error) {
    console.error("Falha ao confirmar importação", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao confirmar importação." }, { status: 500 });
  }
}

