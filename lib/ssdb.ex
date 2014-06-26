defmodule SSDB do
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

  defp call(pid, request) do
    GenServer.call(pid, {:request, to_binary(request)})
  end

  defp to_binary(args) do
    bin = Enum.map(args, fn(arg) -> "#{byte_size(arg)}\n#{arg}\n" end)
    bin ++ ["\n"]
  end
end
