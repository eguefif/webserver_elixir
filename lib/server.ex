defmodule Server.Acceptor do
  alias Server.Header

  def listen() do
    IO.puts("Logs from your program will appear here!")

    {:ok, socket} = :gen_tcp.listen(4221, [:binary, active: false, reuseaddr: true])
    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.ServerSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  def serve(socket) do
    [request, body] =
      socket
      |> read_line()
      |> parse_request()

    case {request.method, request.path} do
      {:get, []} ->
        Server.Response.response_200(socket, "", request)

      {:get, ["files" | path]} ->
        Server.Files.response_files(socket, path, request)

      {:post, ["files" | path]} ->
        Server.Files.create_file(socket, path, body)

      {:get, ["index.html"]} ->
        Server.Response.response_200(socket, "", request)

      {:get, ["user-agent"]} ->
        user_agent = Header.get_header(request, "User-Agent")
        Server.Response.response_200(socket, user_agent, request)

      {:get, ["echo", id]} ->
        Server.Response.response_200(socket, id, request)

      {_, _} ->
        Server.Response.response_404(socket)
    end

    :gen_tcp.close(socket)
  end

  def read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  def parse_request(request) do
    [header, body] = String.split(request, "\r\n\r\n")
    header = Header.get_header(header)
    IO.inspect(header)
    [header, body]
  end
end
