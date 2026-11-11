module RuboCop
  module Cop
    module Silvalde
      # ActiveRecord methods that read or write the database. Shared by the
      # project cops that keep queries inside the services (see AGENTS.md,
      # «Arquitectura obligatoria»).
      QUERY_METHODS = %i[
        all any? authenticate_by count create create! delete_all destroy_all
        exists? find find_by find_by! find_each find_or_create_by
        find_or_create_by! find_or_initialize_by find_sole_by first first!
        includes joins last last! limit order pluck sole sum update_all
        upsert upsert_all insert_all where
      ].to_set.freeze
    end
  end
end
