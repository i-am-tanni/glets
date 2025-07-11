/// A cache is a process that owns an erlang ets table.
/// 
/// ## One Writer, Many Readers
/// 
/// A cache has many readers, which means lookups can be performed conveniently
/// by a caller without message passing.
/// On the other hand, a cache has only one writer, so any writing must be 
/// communicated via message passing to table owner.
/// 
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import gleam/string
import glets/table

/// A cache's owner process receives insertions and deletions as messages.
/// This restriction maintains one writer and many readers.
/// Reading does not require message passing. 
/// 
pub type Message(k, v) {
  InsertMany(objects: List(#(k, v)))
  Insert(key: k, val: v)
  Delete(key: k)
}

/// Starts a simple cache with an API for insertions and deletions.
/// 
pub fn start(
  table_name: process.Name(Message(k, v)),
) -> Result(actor.Started(Subject(Message(k, v))), actor.StartError) {
  actor.new_with_initialiser(100, fn(self) { init(self, table_name) })
  |> actor.named(table_name)
  |> actor.on_message(recv)
  |> actor.start
}

fn init(
  self: Subject(Message(k, v)),
  table_name: process.Name(Message(k, v)),
) -> Result(
  actor.Initialised(
    table.Set(k, v),
    Message(k, v),
    process.Subject(Message(k, v)),
  ),
  String,
) {
  let start_table =
    table_name
    |> table.new
    |> table.set
    |> result.replace_error(
      "Failed to start ets table: " <> string.inspect(table_name),
    )

  use table <- result.try(start_table)
  table
  |> actor.initialised()
  |> actor.returning(self)
  |> Ok
}

/// A basic API for inserting and deleting from the key-val store.
/// 
fn recv(
  table: table.Set(k, v),
  msg: Message(k, v),
) -> actor.Next(table.Set(k, v), Message(k, v)) {
  case msg {
    InsertMany(objects:) -> table.insert_many(table, objects)
    Insert(key:, val:) -> table.insert(table, key, val)
    Delete(key:) -> table.delete(table, key)
  }
  actor.continue(table)
}

/// Perform a lookup on the table from the caller.
/// 
pub fn lookup(table_name: process.Name(Message(k, v)), key: a) {
  table.lookup(table_name, key)
}
