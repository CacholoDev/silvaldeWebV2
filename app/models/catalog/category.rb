module Catalog
  class Category < ApplicationRecord
    self.table_name = "categories"

    # Keep the model name as "Category" (not "Catalog::Category") so the i18n
    # keys (activerecord.errors.models.category.*) and form params stay clean.
    def self.model_name
      ActiveModel::Name.new(self, nil, "Category")
    end

    NAME_MAX_LENGTH = 100
    SLUG_MAX_LENGTH = 150

    # A category that still has products cannot be deleted, so the catalog
    # is never silently broken.
    has_many :products, dependent: :restrict_with_exception, inverse_of: :category

    # Normalize slug to a URL-safe form ("Jarrones de cristal" ->
    # "jarrones-de-cristal"), like email normalization in Users::User.
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

    private

    def generate_slug_from_name
      self.slug = name.to_s.parameterize
    end
  end
end
