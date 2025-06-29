# glets

Bindings for Erlang's ETS module in Gleam

## Table

A library that provides bindings for erlang's ETS library (Erlang Term Storage) for optimized in-memory key-value stores.

## Cache

A module that provides an API to start a named actor that owns a `protected` table and receives messages for insertions and deletions.
Lookups can be performed concurrently outside of the ownership process.
