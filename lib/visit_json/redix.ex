defmodule VisitJson.Redix do
  @moduledoc false

  def get_links(from, to) do
    {:ok, result} = Redix.command(:redix, ["KEYS", "domains:*"])
    links =
      Enum.reduce(
        result,
        [],
        fn elem, acc ->
          stringNum = hd tl String.split(elem, ":")
          {value, _} = Integer.parse(stringNum)
          if value >= from and value <= to do
            acc ++ [value]
          else
            acc
          end
        end
      )
      |> Enum.reduce(
           [],
           fn elem, acc ->
             acc ++ get_links_by_key(elem)
           end
         )
      |> Enum.uniq
    {:ok, links}
  end

  defp get_links_by_key(key) do
    {:ok, result} = Redix.command(:redix, ["LRANGE", "domains:" <> Integer.to_string(key), "0", "-1"])
    #    IO.inspect ["LRANGE", key, "0", "-1"]
    result
  end

  def insert_domains_by_time(domains, time) do
    Redix.command(:redix, ["RPUSH", "domains:" <> Integer.to_string(time)] ++ domains)
    # TODO: Should make :debug variable for output?
    #    IO.inspect ["RPUSH", time, domains]
  end
end
