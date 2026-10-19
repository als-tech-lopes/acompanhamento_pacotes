create or replace view public.vw_backlog as
select *, case when dias_atraso <= 1 then 'Até 1 dia' when dias_atraso <= 3 then '2 a 3 dias'
when dias_atraso <= 7 then '4 a 7 dias' else 'Mais de 7 dias' end as faixa_aging
from public.silver_entregas
where coalesce(status_pacote,'') not in ('entregue','assinado','devolvido','cancelado') and not eh_duplicado;

