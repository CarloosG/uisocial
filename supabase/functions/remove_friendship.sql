create or replace function remove_friendship(
  user_id_param uuid,
  friend_id_param uuid
) returns void as $$
begin
  -- Eliminar registros de la tabla friends
  delete from friends
  where (user_id = user_id_param and friend_id = friend_id_param)
     or (user_id = friend_id_param and friend_id = user_id_param);

  -- Buscar y actualizar la solicitud existente a 'removed'
  update friendships
  set status = 'removed',
      updated_at = now()
  where (user_id = user_id_param and friend_id = friend_id_param)
     or (user_id = friend_id_param and friend_id = user_id_param);

  -- Si no existe una solicitud previa, crear una nueva con estado 'removed'
  if not found then
    insert into friendships (user_id, friend_id, status)
    values (user_id_param, friend_id_param, 'removed');
  end if;
end;
$$ language plpgsql; 