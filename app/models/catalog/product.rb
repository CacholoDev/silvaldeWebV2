module Catalog
  class Product < ApplicationRecord
    self.table_name = "products"

    # Keep the model name as "Product" (not "Catalog::Product") so the i18n
    # keys (activerecord.errors.models.product.*) and form params stay clean.
    def self.model_name
      ActiveModel::Name.new(self, nil, "Product")
    end

    NAME_MAX_LENGTH = 150
    SLUG_MAX_LENGTH = 200

    belongs_to :category, inverse_of: :products

    has_many :variants, dependent: :destroy, inverse_of: :product

    # Normalize slug to a URL-safe form ("Jarrón artesanal" ->
    # "jarron-artesanal"), like email normalization in Users::User.
    normalizes :slug, with: ->(slug) { slug.to_s.parameterize }

    # The slug is generated from the name only when missing, so changing the
    # name later never breaks existing URLs.
    before_validation :generate_slug_from_name, if: -> { slug.blank? }

    validates :name,
              presence: true,
              length: { maximum: NAME_MAX_LENGTH },
              uniqueness: { case_sensitive: false }

    validates :slug,
              presence: true,
              length: { maximum: SLUG_MAX_LENGTH },
              uniqueness: true

    validates :description, presence: true

    validates :price_cents, presence: true
    validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    # A product is available when at least one of its variants has stock.
    # A product without variants is a draft and is not for sale: the variant
    # is what carries stock, so every sellable product needs at least one.
    def available?
      variants.any?(&:available?)
    end

    private

    def generate_slug_from_name
      self.slug = name.to_s.parameterize
    end
  end
end
