module Catalog
  # Public category page: the products of one category.
  # Lookups are delegated to Catalog::Search (controllers never query the DB).
  class CategoriesController < ApplicationController
    def show
      @category = Search.category_by_slug!(params[:slug])
      @products = Search.products_for_category(@category)
    end
  end
end
