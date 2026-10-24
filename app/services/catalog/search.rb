module Catalog
  # Encapsulates the read queries of the catalog domain. Use-case services
  # and controllers delegate their lookups here instead of querying models
  # directly (same pattern as Auth::Search).
  class Search
    # Every product with variants preloaded, ordered by name.
    def self.products
      Product.includes(:variants).order(:name)
    end

    # Products whose name or description match the query. Matching is case
    # and accent insensitive (MySQL utf8mb4_0900_ai_ci collation) and LIKE
    # wildcards in the query are treated as literal text. A blank query
    # returns every product (an empty search box lists the whole catalog).
    def self.products_matching(query)
      return products if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.to_s.strip)}%"
      products.where("products.name LIKE :query OR products.description LIKE :query", query: pattern)
    end

    # Products of a category with variants preloaded.
    def self.products_for_category(category)
      products.where(category: category)
    end

    # Finds a product by its public slug (URL), or nil.
    def self.product_by_slug(slug)
      products.find_by(slug: slug)
    end

    # Finds a category by its public slug (URL), or nil.
    def self.category_by_slug(slug)
      Category.find_by(slug: slug)
    end
  end
end
