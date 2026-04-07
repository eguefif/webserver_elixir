defmodule Server.Files do
  def response_files(socket, path, request) do
    base_path = get_base_path()

    path = Path.join([base_path] ++ path)
    IO.inspect(path)

    case File.read(path) do
      {:ok, data} ->
        Server.Response.response_200(socket, data, request, "application/octet-stream")

      {:error, reason} ->
        IO.puts("Reason")
        IO.inspect(reason)
        Server.Response.response_404(socket)
    end
  end

  def create_file(socket, path, body, request) do
    base_path = get_base_path()
    path = Path.join([base_path] ++ path)

    case File.write(path, body, [:binary]) do
      :ok ->
        Server.Response.response_201(socket, request)

      {:error, reason} ->
        IO.inspect(reason)
        Server.Response.response_404(socket)
    end
  end

  defp get_base_path() do
    args = System.argv()
    pairs = Enum.chunk_every(args, 2) |> Enum.map(fn entry -> List.to_tuple(entry) end)

    IO.inspect(pairs)

    case List.keyfind(pairs, "--directory", 0) do
      nil ->
        "/tmp/"

      {_, path} ->
        path
    end
  end
end
