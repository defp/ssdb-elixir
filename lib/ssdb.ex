defmodule SSDB do

  @type status :: :ok | :error | :fail | :not_found | :client_error

  @doc """
  Connect to the ssdb server 
  options default is 

  ```
    [ host: '127.0.0.1', port: 8888 ]
  ```
  Returns pid of the connected client
  """
  @spec start(Keyword.t) :: GenServer.on_start
  def start(options \\  []) do
    GenServer.start SSDB.Server, options, [name: :ssdb]
  end

  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(options \\ []) do
    GenServer.start_link SSDB.Server,  options, [name: :ssdb]
  end

  @doc """
  Disconnect from the ssdb server
  """
  @spec stop(pid) :: :ok
  def stop(pid) do
    GenServer.call(pid || client_pid(), :stop)
  end

  @doc """
  Send request to ssdb server, request is a list with command and args

  ```
  SSDB.query pid, ["set", "a", "1"]
  ```
  or

  ```
  SSDB.query ["set", "a", "1"]
  ```
  """
  @spec query(pid, list) :: {status, list}
  def query(pid \\ client_pid(), request) when is_list(request) do
    GenServer.call(pid, {:request, request})
  end

  @doc """
    Get process pid
  """
  @spec client_pid() :: pid
  def client_pid do
    Process.whereis(:ssdb)
  end
end
