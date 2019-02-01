defmodule Link.DB do
    def get_url_record(query) do
        Mongo.find(:mongo, "urls", query, pool: DBConnection.Poolboy) |> Enum.to_list |> List.first
    end

    def update_one(query, new_data) do
        Mongo.update_one(:mongo, "urls", query, new_data, pool: DBConnection.Poolboy)
    end
 end