module Catalog
  # XML sitemap with the public catalog URLs (products and categories).
  # Crawlers use it to discover the shop; see public/robots.txt.
  class SitemapController < ApplicationController
    def show
      @products = Search.products

      render formats: :xml
    end
  end
end
