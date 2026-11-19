module Orders
  # The checkout flow: the order form, its submission and the confirmation
  # page. The controller only orchestrates: reads go through Carts::Search
  # and Orders::Search, and the write is the Orders::Checkout use case
  # (controllers never query the DB).
  class CheckoutsController < ApplicationController
    def new
      return redirect_to cart_path, notice: t("checkout.empty_cart") if cart_lines.empty?

      @order = Order.new(contact_name: current_user&.name, contact_email: current_user&.email)
    end

    def create
      order = Checkout.call(cart: current_cart, user: current_user, **order_attributes)

      if order.persisted?
        # The confirmation page reads the order back from the session, so a
        # refresh (F5) keeps working and the number never travels in the URL.
        session[:last_order_number] = order.number
        redirect_to checkout_confirmation_path
      elsif order.errors.added?(:base, :cart_empty)
        redirect_to cart_path, notice: t("checkout.empty_cart")
      else
        @order = order
        render :new, status: :unprocessable_content
      end
    end

    def confirmation
      @order = Search.find_order_by_number(session[:last_order_number])
      redirect_to root_path, alert: t("checkout.nothing_to_confirm") if @order.nil?
    end

    private

    def cart_lines
      Carts::Search.items_for(current_cart)
    end

    def order_attributes
      params.require(:order).permit(:contact_name, :contact_email, :contact_phone,
                                    :pickup_store, :payment_method).to_h.symbolize_keys
    end
  end
end
