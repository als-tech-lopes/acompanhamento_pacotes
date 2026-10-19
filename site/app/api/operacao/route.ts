import { getSupabaseAdmin } from "@/lib/supabase-admin";
import { requireApiAccess } from "@/lib/api-access";

export async function GET(request: Request) {
  const denied = requireApiAccess(request);
  if (denied) return denied;
  try {
    const admin = getSupabaseAdmin();
    // Execute the expensive aggregate before the smaller queries. Running all
    // four concurrently made PostgreSQL exceed its statement timeout on large bases.
    const summary = await admin.from("vw_resumo_operacional").select("*").single();
    if (summary.error) throw summary.error;
    const [shipments, imports, goals] = await Promise.all([
      admin.from("vw_entregas_atuais").select("id,numero_waybill,numero_pedido_anjun,nome_cliente,cidade_destinatario,uf_destinatario,status_pacote,ultimo_rastreio,data_ultimo_rastreio,dias_atraso,horas_sem_movimentacao,status_sla,regiao,cep_destinatario,tipo_pacote,ponto_entrada,ponto_entrega,entregador,tipo_assinatura,motivo_ocorrencia,prazo_calculado,data_criacao_pedido").or("dias_atraso.gt.0,horas_sem_movimentacao.gt.24").order("dias_atraso", { ascending: false, nullsFirst: false }).limit(8),
      admin.from("importacoes").select("id,nome_arquivo,tamanho_bytes,status,etapa,progresso,total_linhas,total_colunas,colunas_mapeadas,colunas_nao_mapeadas,linhas_validas,linhas_erro,linhas_duplicadas,storage_original_path,storage_parquet_path,mensagem_erro,iniciada_em,concluida_em,versao_layout,metadados").order("iniciada_em", { ascending: false }).limit(50),
      admin.from("metas_sla").select("chave,nome,valor,unidade,descricao,updated_at").order("nome"),
    ]);
    for (const result of [shipments, imports, goals]) if (result.error) throw result.error;
    const latestMapping = (imports.data ?? []).find((item) => Array.isArray(item.metadados?.mapping))?.metadados?.mapping ?? [];
    const now = Date.now();
    const currentShipments = (shipments.data ?? []).map((item) => ({
      ...item,
      horas_sem_movimentacao: item.data_ultimo_rastreio
        ? Math.max(0, (now - new Date(item.data_ultimo_rastreio).getTime()) / 3_600_000)
        : null,
    }));
    return Response.json({ summary: summary.data, shipments: currentShipments, imports: imports.data ?? [], goals: goals.data ?? [], mapping: latestMapping });
  } catch (error) {
    console.error("Falha ao carregar operação", error);
    return Response.json({ error: error instanceof Error ? error.message : "Falha ao carregar dados operacionais." }, { status: 500 });
  }
}
