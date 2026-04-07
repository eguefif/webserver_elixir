defmodule Server do
  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Server.ServerSupervisor},
      {Task, fn -> Server.Acceptor.listen() end}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)
    Process.sleep(:infinity)
  end
end
