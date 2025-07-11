import gleeunit/should
import glets/table

pub type TestTable {
  TestTable
}

/// We will test that if a record is provided as a table name in lieu of a unit
/// type, that the request will fail.
/// 
pub type Record {
  Record(Int)
}

pub type MissingTable {
  MissingTable
}

pub type Key {
  // This key will be provided in a test. We will test that the lookup succeeds.
  Key
  /// This key will not be inserted for the purposes of tests. We will test
  /// that a lookup on it will fail as expected.
  MissingKey
}

pub fn basic_table_test() {
  let result = table.new(TestTable) |> table.set()
  should.be_ok(result)
}

/// Since a generic is used for the table name, a run-time check must be
/// performed to test that the table name is an atom (unit type).
/// This tests that passing in a record as the table name results in an error.
/// 
pub fn table_name_must_valid_test() {
  let result = table.new(Record(1)) |> table.set()
  should.be_error(result)
}

pub fn insert_val_test() {
  let assert Ok(table) = table.whereis(TestTable)
  assert table.insert(table, Key, 1)
}

pub fn lookup_test() {
  let is_success = case table.lookup(TestTable, Key) {
    Ok(x) if x == 1 -> True
    _ -> False
  }
  assert is_success
}

pub fn delete_test() {
  let assert Ok(table) = table.whereis(TestTable)
  assert table.delete(table, Key)
}

pub fn lookup_bad_table_name_test() {
  should.be_error(table.lookup(MissingTable, Key))
}

pub fn lookup_bad_key() {
  should.be_error(table.lookup(MissingTable, MissingKey))
}

pub fn whereis_bad_table_name() {
  should.be_error(table.whereis(Record(1)))
}
