import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

const allowedExtensions = new Set(["xlsx", "xls", "csv"]);
const sanitizeName = (name: string) => name.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-zA-Z0-9._-]/g, "_").slice(-180);

export async function POST(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const body = await request.json() as { name?: string; size?: number; type?: string };
    const name = String(body.name ?? ""); const size = Number(body.size ?? 0);
    const extension = name.split(".").pop()?.toLowerCase() ?? "";
    if (!allowedExtensions.has(extension)) return Response.json({ error: "Formato não suportado." }, { status: 400 });
    if (!Number.isInteger(size) || size <= 0 || size > 250 * 1024 * 1024) return Response.json({ error: "O arquivo deve ter entre 1 byte e 250 MB." }, { status: 400 });
    const admin = getSupabaseAdmin();
    const { error: cancelError } = await admin.from("importacoes").update({ status: "cancelada", etapa: "upload_interrompido", mensagem_erro: "Envio anterior substituído após interrupção.", updated_at: new Date().toISOString() }).eq("status", "aguardando_upload").eq("nome_arquivo", name).eq("tamanho_bytes", size);
    if (cancelError) throw cancelError;
    const id = crypto.randomUUID(); const path = `originais/${id}/${sanitizeName(name)}`;
    const { error: insertError } = await admin.from("importacoes").insert({ id, nome_arquivo: name, tamanho_bytes: size, storage_original_path: path, status: "aguardando_upload", etapa: "upload", progresso: 0, metadados: { content_type: body.type ?? null } });
    if (insertError) throw insertError;
    const { data, error } = await admin.storage.from("importacoes").createSignedUploadUrl(path);
    if (error) throw error;
    return Response.json({ id, path, token: data.token, endpoint: process.env.NEXT_PUBLIC_SUPABASE_URL, apiKey: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY });
  } catch (error) {
    console.error("Falha ao iniciar importação", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao iniciar importação." }, { status: 500 });
  }
}

