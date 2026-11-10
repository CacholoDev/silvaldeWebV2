require_relative "query_methods"

module RuboCop
  module Cop
    module Silvalde
      # Controllers orchestrate (authorize → service → respond) and never talk
      # to the database: reads go through `<Context>::Search` and writes
      # through the use-case services.
      #
      # It flags query methods called on a constant (`Users::User.find`,
      # `Catalog::Product.where`). Building a blank record for a form
      # (`Users::User.new`) is allowed.
      #
      # @example
      #   # bad
      #   @product = Catalog::Product.find_by!(slug: params[:slug])
      #
      #   # good
      #   @product = Catalog::Search.product_by_slug!(params[:slug])
      class NoActiveRecordInControllers < Base
        MSG = "Controllers must not query the database (`%<receiver>s.%<method>s`). " \
              "Move the read to `<Context>::Search` or the write to a use-case service."

        def on_send(node)
          return unless QUERY_METHODS.include?(node.method_name)

          receiver = node.receiver
          return unless receiver&.const_type?
          return if receiver.short_name.to_s.end_with?("Search")

          add_offense(node, message: format(MSG, receiver: receiver.source, method: node.method_name))
        end
        alias on_csend on_send
      end
    end
  end
end
