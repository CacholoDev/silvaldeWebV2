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
        quantity: params[:quantity].to_s.to_i,
        user: current_user
      )
      self.current_cart = item.cart if item.errors.empty?

      respond_to do |format|
        format.html { redirect_with_flash(variant, item) }
        format.turbo_stream { render_turbo_feedback(item) }
      end
    end

    def update
      item = Carts::Search.find_item_by_id!(current_cart, params[:id])
      Carts::UpdateQuantity.call(item: item, quantity: params[:quantity].to_s.to_i)

      if item.errors.empty?
        respond_to do |format|
          format.html { redirect_to cart_path, notice: t("cart.updated") }
          format.turbo_stream { render_cart_refresh(t("cart.updated")) }
        end
      else
        respond_to do |format|
          format.html { redirect_to cart_path, alert: t("cart.update_failed") }
          format.turbo_stream do
            render status: :unprocessable_content,
                   turbo_stream: turbo_stream.update("cart_feedback", t("cart.update_failed"))
          end
        end
      end
    end

    def destroy
      item = Carts::Search.find_item_by_id!(current_cart, params[:id])
      Carts::RemoveItem.call(item: item)

      respond_to do |format|
        format.html { redirect_to cart_path, notice: t("cart.removed") }
        format.turbo_stream { render_cart_refresh(t("cart.removed")) }
      end
    end

    private

    # Re-renders the cart pieces affected by a change: the lines and total
    # (or the empty state), the header counter and the feedback message.
    def render_cart_refresh(message)
      render turbo_stream: [
        turbo_stream.update("cart_contents", partial: "carts/carts/contents",
                                            locals: { items: Carts::Search.items_for(current_cart),
                                                      total_cents: Carts::Search.total_cents(current_cart) }),
        turbo_stream.update("cart_counter", partial: "shared/cart_counter",
                                            locals: { count: Carts::Search.total_quantity(current_cart) }),
        turbo_stream.update("cart_feedback", message)
      ]
    end

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
