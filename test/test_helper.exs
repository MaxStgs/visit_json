defmodule VisitJson.TestHelpers do
  def clear_redis_links() do
    Redix.command(:redix, ["FLUSHALL"])
  end
end

ExUnit.start()
