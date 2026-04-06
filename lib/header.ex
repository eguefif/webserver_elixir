defmodule Header do
  defstruct method: "", path: "", protocol: "", headers: []

  def get_header(header_bytes) do
    IO.inspect(header_bytes)
    [request_line, rest] = String.split(header_bytes, "\r\n", parts: 2)
    [method, path, protocol] = String.split(request_line, " ")
    %Header{method: method, path: path, protocol: protocol, headers: parse_headers(rest)}
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
