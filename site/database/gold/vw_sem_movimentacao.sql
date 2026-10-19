create or replace view public.vw_sem_movimentacao as
select *, case when horas_sem_movimentacao > 168 then 'Mais de 7 dias' when horas_sem_movimentacao > 96 then 'Mais de 96 horas'
when horas_sem_movimentacao > 72 then 'Mais de 72 horas' when horas_sem_movimentacao > 48 then 'Mais de 48 horas' else 'Mais de 24 horas' end as faixa_sem_movimentacao
from public.silver_entregas
where coalesce(status_pacote,'') not in ('entregue','assinado','devolvido','cancelado') and horas_sem_movimentacao > 24 and not eh_duplicado;

