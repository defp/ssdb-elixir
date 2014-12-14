SSDB
====

ssdb client for Elixir focus on performance

## Example:

```iex
iex(1)> {:ok, pid} = SSDB.start
{:ok, #PID<0.57.0>}
iex(2)> {:ok, true} = SSDB.set pid, "ssdb", "cool"
{:ok, true}
iex(3)> {:ok, value} = SSDB.get pid, "ssdb"
{:ok, "cool"}
iex(4)> {:ok, num} = SSDB.multi_set pid, %{a: 1, b: 2, c: 3}
{:ok, "3"}
iex(5)> {:ok, map} = SSDB.multi_get pid, ["a", "b", "c"]
{:ok, %{"a" => "1", "b" => "2", "c" => "3"}}
iex(6)> {:ok, num1} = SSDB.multi_del pid, ["a", "b", "c"]
{:ok, "3"}
iex(7)>

```

## Installation

Releases are published through [hex.pm](https://hex.pm/). Add as a dependency in your mix.exs file:

    defp deps do
      [ { :ssdb_elixir, "~> 0.2.4" } ]
    end

TODO:
  * add more command & test
