create or replace view public.vw_sla_cadeia as
select *, (status_sla = 'no_prazo') as entregue_no_prazo
from public.silver_entregas
where status_pacote in ('entregue','assinado') and not eh_duplicado;

