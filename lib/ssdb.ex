defmodule SSDB do
  def start(options \\  []) do
    GenServer.start SSDB.Server, options, []
  end

  def start_link(options \\ []) do
    GenServer.start_link SSDB.Server,  options, []
  end

  def set(pid, key, value) do
    call_server(pid, {"set", key, value})
  end

  def get(pid, key) do
    call_server(pid, {"get", key})
  end

  defp call_server(pid, request) do
    GenServer.call(pid, request)
  end
end
