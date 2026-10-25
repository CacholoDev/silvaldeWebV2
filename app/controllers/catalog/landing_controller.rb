module Catalog
  # Public landing page of the shop: intro, categories, featured products,
  # offers and the photo gallery. Lookups are delegated to Catalog::Search
  # (controllers never query the DB).
  class LandingController < ApplicationController
    def index
      @products = Search.featured_products
      @offers = Search.products_on_offer
      @featured_photos = Search.products_with_photos
    end
  end
end
