defmodule VisitJson.Endpoint do
  @moduledoc """
  Plug for requests
  """

  use Plug.Router

  plug(Plug.Logger)

  plug(:match)

  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)

  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "It works!")
  end

  get "/visited_domains" do
    params = conn.query_params

    # TODO: solve it better
    # convert params(from, to) from string to integers or nil
    {from, _} = cond do
      params["from"] != nil && Integer.parse(params["from"]) ->
        Integer.parse(params["from"])
      true -> {nil, 0}
    end
    {to, _} = cond do
      params["to"] != nil && Integer.parse(params["to"]) ->
        Integer.parse(params["to"])
      true -> {nil, 0}
    end

    {status, body} = cond do
      to == nil || from == nil ->
        {200, resp_missing_from_to()}
      from > to ->
        {200, resp_from_bigger_than_to()}
      true ->
        {200, resp_get_unique_domains(from, to)}
    end

    send_resp(conn, status, body)
  end

  # TODO: maybe I should move that to somewhere?
  defp resp_missing_from_to do
    Poison.encode!(%{"status" => "Missed or Incorret 'from' and/or 'to' params"})
  end

  defp resp_get_unique_domains(from, to) do
    {:ok, domains} = VisitJson.Redix.get_links(from, to)
    Poison.encode!(%{"domains" => domains, "status" => "ok"})
  end

  defp resp_from_bigger_than_to() do
    Poison.encode!(%{"status" => "From is bigger than to"})
  end

  post "/visited_links" do
    handle_visited_links(conn)
  end

  defp handle_visited_links(conn) do
    {status, body} = case conn.params do
      %{"links" => links} ->
        {200, update_links(links)}
      _ ->
        {200, response_missed_links()}
    end

    send_resp(conn, status, body)
  end

  defp update_links(links) do
    domains = VisitJson.Helpers.get_domains_from_links(links)
    VisitJson.Redix.insert_domains_by_time(domains, :os.system_time(:second))
    Poison.encode!(%{"status" => "ok"})
  end

  defp response_missed_links() do
    Poison.encode!(%{"status" => "missed links"})
  end

  # For all unhandled requests
  match _ do
    send_resp(conn, 404, "You are moved somewhere... Q|*_*|Q")
  end
end