defmodule SSDB do

  @type key :: binary | atom
  @type value :: binary | atom | integer


  def start(options \\  []) do
    GenServer.start SSDB.Server, options, []
  end

  def start_link(options \\ []) do
    GenServer.start_link SSDB.Server,  options, []
  end

  def set(pid, key, value) do
    call(pid, ["set", key, value])
  end

  def get(pid, key) do
    call(pid, ["get", key])
  end

  def del(pid, key) do
    call(pid, ["del", key])
  end

  def exists(pid, key) do
    call(pid, ["exists", key])
  end

  def multi_get(pid, keys) do 
    call(pid, ["multi_get" | keys])
  end

  defp call(pid, request) do
    GenServer.call(pid, {:request, create_request(request)})
  end

  defp create_request(args) do
    bin = Enum.map(Enum.map(args, fn(arg) -> to_binary(arg) end),
      fn(arg) -> "#{byte_size(arg)}\n#{arg}\n" end)
    bin ++ ["\n"]
  end

  defp to_binary(x) when is_binary(x), do: x
  defp to_binary(x) when is_integer(x), do: Integer.to_string(x)
  defp to_binary(x) when is_atom(x), do: Atom.to_string(x)
  defp to_binary(x) when is_list(x), do: List.to_string(x)
end
