module Catalog
  # Public product listing (with the search box) and product detail page.
  # Lookups are delegated to Catalog::Search (controllers never query the DB).
  class ProductsController < ApplicationController
    def index
      @query = params[:q]
      @products = Search.products_matching(@query)
    end

    def show
      @product = Search.product_by_slug!(params[:slug])
    end
  end
end
