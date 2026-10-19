import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

export async function PATCH(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const body = await request.json() as { chave?: string; valor?: number };
    const value = Number(body.valor);
    if (!body.chave || !Number.isFinite(value) || value < 0 || value > 1000) return Response.json({ error: "Meta inválida." }, { status: 400 });
    const admin = getSupabaseAdmin();
    const { data, error } = await admin.from("metas_sla").update({ valor: value, updated_at: new Date().toISOString() }).eq("chave", body.chave).select().maybeSingle();
    if (error) throw error;
    if (!data) return Response.json({ error: "Meta não encontrada." }, { status: 404 });
    return Response.json(data);
  } catch (error) {
    console.error("Falha ao atualizar meta", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao atualizar meta." }, { status: 500 });
  }
}
