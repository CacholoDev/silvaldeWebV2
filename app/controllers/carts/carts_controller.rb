module Carts
  # The shopping cart page. The controller only orchestrates: the lookups are
  # delegated to Carts::Search (controllers never query the DB).
  class CartsController < ApplicationController
    def show
      @items = Carts::Search.items_for(current_cart)
      @total_cents = Carts::Search.total_cents(current_cart)
    end
  end
end
