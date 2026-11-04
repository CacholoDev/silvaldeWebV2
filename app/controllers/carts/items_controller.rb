module Carts
  # Adds lines to the shopping cart, the endpoint behind "add to cart".
  # The controller only orchestrates: lookups live in the Search services and
  # writes in the use-case services (Carts::AddItem).
  class ItemsController < ApplicationController
    def create
      variant = Catalog::Search.variant_by_id!(params[:variant_id])
      item = Carts::AddItem.call(
        cart: current_cart,
        variant: variant,
        quantity: params[:quantity].to_i,
        user: current_user
      )
      self.current_cart = item.cart if item.errors.empty?

      respond_to do |format|
        format.html { redirect_with_flash(variant, item) }
        format.turbo_stream { render_turbo_feedback(item) }
      end
    end

    private

    # No-JS fallback: go back to the product page with the outcome as flash.
    def redirect_with_flash(variant, item)
      fallback = product_path(variant.product.slug)
      if item.errors.empty?
        redirect_back fallback_location: fallback, notice: t("cart.added")
      else
        redirect_back fallback_location: fallback, alert: t("cart.add_failed")
      end
    end

    # Turbo: refresh the header counter and report the outcome next to the
    # form, without reloading the page.
    def render_turbo_feedback(item)
      if item.errors.empty?
        render turbo_stream: [
          turbo_stream.update("cart_counter", partial: "shared/cart_counter",
                                              locals: { count: Carts::Search.total_quantity(item.cart) }),
          turbo_stream.update("cart_feedback", t("cart.added"))
        ]
      else
        render status: :unprocessable_content,
               turbo_stream: turbo_stream.update("cart_feedback", t("cart.add_failed"))
      end
    end
  end
end
