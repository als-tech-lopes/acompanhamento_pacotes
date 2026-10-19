create or replace view public.vw_sla_last_mile as
select *, case when data_hora_primeira_entrega <= prazo_calculado then 'no_prazo' else 'fora_prazo' end as sla_last_mile
from public.silver_entregas where data_hora_entrega_ponto is not null and not eh_duplicado;

