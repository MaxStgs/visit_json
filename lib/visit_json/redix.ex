defmodule VisitJson.Redix do
  @moduledoc false

  def get_links(from, to) do
    {:ok, keys} = Redix.command(:redix, ["KEYS", "domains:*"])
    links =
      keys
      |> prepare_keys(from, to)
      |> prepare_commands_for_get
      |> pipeline_get
      |> Enum.uniq
    {:ok, links}
  end

  defp prepare_keys(keys, from, to) do
    Enum.filter(
      keys,
      fn elem ->
        stringNum = hd tl String.split(elem, ":")
        {value, _} = Integer.parse(stringNum)
        if value >= from and value <= to do
          elem
        end
      end
    )
  end

  defp prepare_commands_for_get(keys) do
    Enum.map(keys, fn elem -> ["LRANGE", elem, "0", "-1"] end)
  end

  def pipeline_get(commands) do
    if length(commands) != 0 do
      {:ok, result} = Redix.pipeline(:redix, commands)
      result
      |> Enum.reduce([], fn elem, acc -> acc ++ elem end)
    else
      []
    end
  end

  def insert_domains_by_time(domains, time) do
    Redix.command(:redix, ["RPUSH", "domains:" <> Integer.to_string(time)] ++ domains)
#    IO.inspect ["RPUSH", time, domains]
  end
end
