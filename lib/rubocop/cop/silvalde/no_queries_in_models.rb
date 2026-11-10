require_relative "query_methods"

module RuboCop
  module Cop
    module Silvalde
      # Models hold associations, validations and parameterless behaviour on
      # their own state. They never query: no `scope`/`default_scope` and no
      # query methods on the class itself. Reads live in
      # `app/services/<context>/search.rb`.
      #
      # @example
      #   # bad
      #   scope :active, -> { where(used_at: nil) }
      #   def self.recent = where(created_at: 1.day.ago..)
      #
      #   # good (app/services/auth/search.rb)
      #   def self.active_password_reset_tokens
      #     PasswordResetToken.where(used_at: nil)
      #   end
      class NoQueriesInModels < Base
        SCOPE_MSG = "Models must not define `%<method>s`. Move the query to `<Context>::Search`."
        QUERY_MSG = "Models must not query (`%<method>s`). Move the query to `<Context>::Search`."

        def on_send(node)
          receiver = node.receiver
          return unless receiver.nil? || receiver.self_type?

          if %i[scope default_scope].include?(node.method_name)
            add_offense(node, message: format(SCOPE_MSG, method: node.method_name))
          elsif QUERY_METHODS.include?(node.method_name)
            add_offense(node, message: format(QUERY_MSG, method: node.method_name))
          end
        end
      end
    end
  end
end
