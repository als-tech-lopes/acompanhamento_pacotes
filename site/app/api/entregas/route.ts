import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

const columns = "id,numero_waybill,numero_pedido_anjun,nome_cliente,cidade_destinatario,uf_destinatario,status_pacote,ultimo_rastreio,data_ultimo_rastreio,dias_atraso,horas_sem_movimentacao,status_sla,regiao,cep_destinatario,tipo_pacote,ponto_entrada,ponto_entrega,entregador,tipo_assinatura,motivo_ocorrencia,prazo_calculado,data_criacao_pedido";

export async function GET(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const params = new URL(request.url).searchParams;
    const page = Math.max(1, Math.floor(Number(params.get("page")) || 1));
    const pageSize = Math.min(100, Math.max(10, Math.floor(Number(params.get("pageSize")) || 20)));
    const search = (params.get("search") ?? "").trim().replace(/[,%()]/g, " ").slice(0, 100);
    const status = (params.get("status") ?? "").trim().slice(0, 150);
    const from = (page - 1) * pageSize;
    const admin = getSupabaseAdmin();
    let query = admin.from("vw_entregas_atuais").select(columns, { count: "exact" });
    if (search) query = query.or(`numero_waybill.ilike.%${search}%,numero_pedido_anjun.ilike.%${search}%,nome_cliente.ilike.%${search}%,cidade_destinatario.ilike.%${search}%`);
    if (status) query = query.eq("status_pacote", status);
    const { data, count, error } = await query.order("data_ultimo_rastreio", { ascending: false, nullsFirst: false }).range(from, from + pageSize - 1);
    if (error) throw error;
    const now = Date.now();
    const rows = (data ?? []).map((item) => ({
      ...item,
      horas_sem_movimentacao: item.data_ultimo_rastreio
        ? Math.max(0, (now - new Date(item.data_ultimo_rastreio).getTime()) / 3_600_000)
        : null,
    }));
    return Response.json({ rows, count: count ?? 0, page, pageSize });
  } catch (error) {
    console.error("Falha ao consultar entregas", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao consultar entregas." }, { status: 500 });
  }
}
