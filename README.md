SSDB client
==============

[![Build Status](https://travis-ci.org/lidashuang/ssdb-elixir.svg?branch=master)](https://travis-ci.org/lidashuang/ssdb-elixir)

SSDB client for Elixir

## Installation

Releases are published through [hex.pm](https://hex.pm/). Add as a dependency in your mix.exs file:

```elixir
defp deps do
  [ { :ssdb, "~> 0.3.0" } ]
end
```

## Example:

```elixir
Interactive Elixir (1.0.2) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> {:ok, pid} = SSDB.start
{:ok, #PID<0.79.0>}
iex(2)> SSDB.query pid,  ["set", "ssdb", "cool"]
{:ok, ["1"]}
iex(3)> SSDB.query ["get", "ssdb"]
{:ok, ["cool"]}
iex(4)> SSDB.query ["exists", "ssdb"]
{:ok, ["1"]}
iex(5)>
```
