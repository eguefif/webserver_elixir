defmodule Server.Header do
  defstruct method: "", path: [], protocol: "", headers: []

  def get_header(header_bytes) do
    IO.inspect(header_bytes)
    # This crashes because there are no headers
    case String.split(header_bytes, "\r\n", parts: 2) do
      [request_line] ->
        [method, path, protocol] = String.split(request_line, " ")

        %Server.Header{
          method: method,
          path: parse_path(path),
          protocol: protocol,
          headers: []
        }

      [request_line, rest] ->
        [method, path, protocol] = String.split(request_line, " ")
        headers = parse_headers(rest)

        %Server.Header{
          method: method,
          path: parse_path(path),
          protocol: protocol,
          headers: headers
        }
    end
  end

  def get_header(request, lookfor_header) do
    result =
      Enum.find(request.headers, :not_found, fn header ->
        elem(header, 0) == String.trim(lookfor_header)
      end)

    case result do
      :not_found -> ""
      header -> elem(header, 1)
    end
  end

  defp parse_path(path) do
    String.split(path, "/", trim: true)
  end

  defp parse_headers(headers_bytes) do
    splits = String.split(headers_bytes, "\r\n", parts: 2)

    case splits do
      [] ->
        []

      [last_header] ->
        header = process_one_header(last_header)
        [header]

      [current_header, rest] ->
        headers = parse_headers(rest)
        header = process_one_header(current_header)
        headers ++ [header]
    end
  end

  defp process_one_header(header_bytes) do
    String.split(header_bytes, ":", trim: true, parts: 2)
    |> Enum.map(fn entry -> String.trim(entry) end)
    |> List.to_tuple()
  end
end
