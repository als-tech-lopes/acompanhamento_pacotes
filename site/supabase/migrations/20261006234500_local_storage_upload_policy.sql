-- Política temporária para desenvolvimento local sem autenticação.
-- Antes da produção, substituir por política authenticated vinculada à empresa do usuário.
create policy "local_anon_insert_importacoes"
on storage.objects for insert to anon
with check (bucket_id = 'importacoes' and (storage.foldername(name))[1] = 'originais');
