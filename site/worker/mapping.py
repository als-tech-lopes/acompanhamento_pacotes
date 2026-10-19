import re
import unicodedata

PAIRS = [
 ("Número do Waybill","numero_waybill"),("Número de ordem de escaneamento","numero_ordem_escaneamento"),("Número do pedido Anjun","numero_pedido_anjun"),("Tipo do pacote","tipo_pacote"),("Status do Pacote","status_pacote"),
 ("Último data de rastreio","data_ultimo_rastreio"),("Último rastreio","ultimo_rastreio"),("Último ponto de rastreio","ultimo_ponto_rastreio"),("Motivo da Ocorrência","motivo_ocorrencia"),("Tag","tag"),("Tipo do pedido","tipo_pedido"),
 ("Estado do destinatário","uf_destinatario"),("Cidade do destinatário","cidade_destinatario"),("Bairro do destinatário","bairro_destinatario"),("Rua do destinatário","rua_destinatario"),("CEP do destinatário","cep_destinatario"),
 ("Zona","zona_destinatario"),("Tipo de cidade","tipo_cidade_destinatario"),("Estado de origem","uf_origem"),("Cidade do remetente","cidade_remetente"),("Hierarquia urbana de origem","hierarquia_urbana_origem"),
 ("Nome do cliente","nome_cliente"),("Nome do Cliente Merchant","nome_cliente_merchant"),("Região","regiao"),("Ponto de Pré-entrega","ponto_pre_entrega"),("Ponto de entrada","ponto_entrada"),
 ("Estado do ponto de entrada","uf_ponto_entrada"),("Ponto de entrega","ponto_entrega"),("entregador","entregador"),("Tipo de coleta","tipo_coleta"),("Tipo de assinatura","tipo_assinatura"),
 ("Tipo do destinatário","tipo_destinatario"),("Relação do Destinatário","relacao_destinatario"),("Criação de pedido","data_criacao_pedido"),("Saída do armazém do cliente","data_saida_armazem_cliente"),("Coleta de LM","data_coleta_lm"),
 ("Carregamento da coleta","data_carregamento_coleta"),("Próxima Parada da Coleta","proxima_parada_coleta"),("Range rover duração (horas)","duracao_range_rover_horas"),("Tempo de Transporte de Coleta(H)","tempo_transporte_coleta_horas"),
 ("Fechamento do veículo da coleta","data_fechamento_veiculo_coleta"),("Abertura do veículo do HUB1","data_abertura_veiculo_hub1"),("Entrada no centro nível 01","data_entrada_centro_nivel_01"),("Saída do centro nível 01","data_saida_centro_nivel_01"),
 ("Fechamento do veículo do HUB1","data_fechamento_veiculo_hub1"),("Duração da operação do centro nível 01","duracao_operacao_centro_nivel_01_horas"),("Abertura do veículo do HUB2","data_abertura_veiculo_hub2"),
 ("Entrada no centro nível 02","data_entrada_centro_nivel_02"),("Saída do centro nível 02","data_saida_centro_nivel_02"),("Fechamento do veículo do HUB2","data_fechamento_veiculo_hub2"),("Duração da operação do centro nível 02","duracao_operacao_centro_nivel_02_horas"),
 ("Abertura do veículo do HUB3","data_abertura_veiculo_hub3"),("Entrada no centro nível 03","data_entrada_centro_nivel_03"),("Saída do centro nível 03","data_saida_centro_nivel_03"),("Tempo de bloqueio do HUB3","tempo_bloqueio_hub3_horas"),
 ("Duração da operação do centro de distribuição nível 03","duracao_operacao_centro_distribuicao_nivel_03_horas"),("Tempo de Desbloquear o veículo","tempo_desbloqueio_veiculo"),("Tempo de inbound no ponto","tempo_inbound_ponto_horas"),
 ("Hora de Entrega do Ponto","data_hora_entrega_ponto"),("Primeiro horário de entrega","primeiro_horario_entrega"),("Segundo horário de entrega","segundo_horario_entrega"),("Terceiro horário de entrega","terceiro_horario_entrega"),
 ("Hora do Primeira Entrega","data_hora_primeira_entrega"),("Tempo de Assinatura","tempo_assinatura"),("Tempo de Despacho do Ponto(H)","tempo_despacho_ponto_horas"),("Tempo de Trânsito de Despacho(H)","tempo_transito_despacho_horas"),
 ("Duração do Primeira Entrega","duracao_primeira_entrega_horas"),("Tempo de Assinatura do Ponto(H)","tempo_assinatura_ponto_horas"),("Tempo Total de Assinatura(H)","tempo_total_assinatura_horas"),
 ("Tempo de Transporte HUB1(H)","tempo_transporte_hub1_horas"),("Tempo de Transporte HUB2(H)","tempo_transporte_hub2_horas"),("Tempo de Transporte HUB3(H)","tempo_transporte_hub3_horas"),
 ("Dias de prazo requisitados por cliente","dias_prazo_requisitados_cliente"),("Horário em que deve ser entregue","horario_limite_entrega"),("O cliente pede o número de dias do ciclo fechado","cliente_solicita_dias_ciclo_fechado"),
 ("Cliente solicita tempo de ciclo fechado","cliente_solicita_tempo_ciclo_fechado"),("Duração do Atraso","duracao_atraso_horas"),("Dias de Atraso","dias_atraso"),("Hora de registro do item com problema","data_registro_item_problema"),
 ("Ponto de registro de problema","ponto_registro_problema"),("Data da primeira devolução do ponto de serviço","data_primeira_devolucao_ponto_servico")
]

def normalize(value):
    value = unicodedata.normalize("NFD", str(value or ""))
    return re.sub(r"\s+", " ", "".join(c for c in value if unicodedata.category(c) != "Mn").lower()).strip()

FIELD_MAP = {normalize(label): field for label, field in PAIRS}

def translated_label(header):
    value = str(header or "").strip()
    boundary = value.find(")(")
    start = boundary + 1 if boundary >= 0 else value.find("(")
    return value[start + 1:-1].strip() if start >= 0 and value.endswith(")") else value

def map_headers(headers):
    arrival_hub = 0; next_hub = 0; result = []
    for index, original in enumerate(headers, 1):
        label = translated_label(original); key = normalize(label); technical = FIELD_MAP.get(key)
        if key == normalize("Centro real de chegada"):
            arrival_hub += 1; technical = f"centro_real_chegada_hub{arrival_hub}"
        if key == normalize("Próximo ponto"):
            next_hub += 1; technical = f"proximo_ponto_hub{next_hub}"
        result.append({"index": index, "original": str(original or ""), "label": label, "technical": technical, "mapped": bool(technical)})
    return result

