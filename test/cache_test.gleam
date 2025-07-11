import gleam/erlang/process
import gleam/otp/actor
import glets/cache
import glets/table

type Owner {
  Owner
}

pub fn cache_ownership_test() {
  let table_name = process.new_name("test_cache")
  let assert Ok(actor.Started(pid:, ..)) = cache.start(table_name)
  let assert Ok(table) = table.whereis(table_name)
  assert ets_info(table, Owner) == pid
}

@external(erlang, "ets", "info")
fn ets_info(table: table.Set(k, v), owner: Owner) -> process.Pid
