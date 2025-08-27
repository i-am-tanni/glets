//// Bindings for Erlang's ETS module (Erlang Term Storage).
////

import gleam/erlang/atom.{type Atom}
import gleam/list

/// An ets table id
/// 
pub type Set(k, v) {
  Set(k, v)
}

/// Privacy options for the table
/// 
pub type Privacy {
  /// Private denotes a table that cannot be accessed outside of the owner 
  /// process neither for writes nor reads.
  /// 
  Private
  /// Protected denotes a table that can be accessed for reads by a process
  /// outside of the owner, but writes can only be performed by the owner
  /// process.
  /// 
  Protected
  /// Public denotes a table that can be accessed outside of the owner process
  /// for both reads and writes.
  /// 
  Public
}

/// A builder for constructing a table.
/// 
pub opaque type TableBuilder(a) {
  TableBuilder(
    name: a,
    privacy: Privacy,
    read_concurrency: Bool,
    write_concurrency: Bool,
    compressed: Bool,
    decentralized_counters: Bool,
  )
}

type Option {
  Option(Atom)
  Property(#(Atom, Bool))
}

/// Intatiates a new builder.
/// 
pub fn new(name: a) -> TableBuilder(a) {
  TableBuilder(
    name: name,
    privacy: Protected,
    read_concurrency: False,
    write_concurrency: False,
    compressed: False,
    decentralized_counters: False,
  )
}

/// Activates the read concurrency option.
/// Only add if you are confident that reads are mostly contiguous.
/// Interleaving reads and writes will lead to slowdown with 
/// `read_concurrency: True`.
/// 
pub fn read_concurrency(builder: TableBuilder(a)) -> TableBuilder(a) {
  TableBuilder(..builder, read_concurrency: True)
}

/// Activates the write concurrency option.
/// Only add if you are confident that reads are mostly contiguous.
/// Interleaving reads and writes will lead to slowdown with 
/// `write_concurrency: True`.
/// 
pub fn write_concurrency(builder: TableBuilder(a)) -> TableBuilder(a) {
  TableBuilder(..builder, write_concurrency: True)
}

/// The table will consume less memory, but slows down table operations.
/// 
pub fn compressed(builder: TableBuilder(a)) -> TableBuilder(a) {
  TableBuilder(..builder, compressed: True)
}

/// Optimizes the table for frequent concurrent calls for insertions and 
/// deletions. The drawback is querying the table for its size and memory
/// will be slower. [Further Information](https://www.erlang.org/blog/scalable-ets-counters/)
/// 
/// 
pub fn decentralized_counters(builder: TableBuilder(a)) -> TableBuilder(a) {
  TableBuilder(..builder, decentralized_counters: True)
}

/// Builds a `set` table
/// 
pub fn set(builder: TableBuilder(a)) -> Result(Set(k, v), Nil) {
  build(builder, "set")
}

/// Builds an `ordered_set` table
/// 
pub fn ordered_set(builder: TableBuilder(a)) -> Result(Set(k, v), Nil) {
  build(builder, "ordered_set")
}

fn build(builder: TableBuilder(a), table_type: String) -> Result(Set(k, v), Nil) {
  let options =
    [
      Option(atom.create(table_type)),
      Option(atom.create("named_table")),
      Option(privacy_to_atom(builder.privacy)),
    ]
    |> property(builder.write_concurrency, "write_concurrency")
    |> property(builder.read_concurrency, "read_concurrency")
    |> property(builder.decentralized_counters, "decentralized_counters")
    |> option(builder.compressed, "compressed")

  ets_new(builder.name, options)
}

fn property(options: List(Option), property: Bool, name: String) -> List(Option) {
  case property {
    True -> [Property(#(atom.create(name), True)), ..options]
    False -> options
  }
}

fn option(options: List(Option), option: Bool, name: String) -> List(Option) {
  case option {
    True -> [Option(atom.create(name)), ..options]
    False -> options
  }
}

/// Inserts a value into the table for a given key.
/// 
/// Note that for a protected table, only the owner process can write to
/// the table.
pub fn insert(table: Set(k, v), key: k, val: v) -> Bool {
  ets_insert_row(table, #(key, val))
}

/// Inserts a list of objects into the table.
/// 
pub fn insert_many(table: Set(k, v), list: List(#(k, v))) -> Bool {
  list.fold(list, True, fn(_, item) { ets_insert_row(table, item) })
}

/// Deletes a key-value pair in the table.
/// 
pub fn delete(table: Set(k, v), key: k) -> Bool {
  ets_delete_row(table, key)
}

/// Drops the whole table.
/// 
pub fn drop(table: Set(k, v)) -> Bool {
  ets_delete_table(table)
}

/// A lookup can be performed by the caller without message passing provided
/// they have the table name, which is internally represented as an atom.
/// 
pub fn lookup(table_name: a, key: k) -> Result(v, Nil) {
  case ets_lookup(table_name, key) {
    Ok([#(_, val)]) -> Ok(val)
    _ -> Error(Nil)
  }
}

/// Confirms if table contains a key
/// 
pub fn has_key(table_name: a, key: k) -> Bool {
  case lookup(table_name, key) {
    Ok(_) -> True
    Error(Nil) -> False
  }
}

pub fn to_list(table_name: a) -> List(#(k, v)) {
  ets_to_list(table_name)
}

/// This function is intended for tests. 
/// Returns the table id given a table name.
/// 
pub fn whereis(table_name: a) -> Result(Set(k, v), Nil) {
  ets_whereis(table_name)
}

@external(erlang, "glets", "new_table")
fn ets_new(name: a, options: List(Option)) -> Result(Set(k, v), Nil)

@external(erlang, "ets", "insert")
fn ets_insert_row(cache: Set(k, v), key_val: #(k, v)) -> Bool

@external(erlang, "glets", "lookup")
fn ets_lookup(cache: a, key: k) -> Result(List(#(k, v)), Nil)

@external(erlang, "ets", "delete")
fn ets_delete_row(cache: Set(k, v), key: k) -> Bool

@external(erlang, "ets", "delete")
fn ets_delete_table(cache: Set(k, v)) -> Bool

@external(erlang, "ets", "tab2list")
fn ets_to_list(cache: a) -> List(#(k, v))

@external(erlang, "glets", "whereis")
fn ets_whereis(table_name: a) -> Result(Set(k, v), Nil)

@external(erlang, "glets", "identity")
fn privacy_to_atom(val: Privacy) -> Atom
