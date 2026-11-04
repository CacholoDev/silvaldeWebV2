class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Namespaced models report their short name ("Product", not
  # "Catalog::Product") so i18n error keys (activerecord.errors.models.product.*)
  # and form params (product[...]) stay clean. This is infrastructure naming,
  # not entity logic: individual models never override it themselves.
  # Memoized per class: it is built once (hot path in forms and dom_id).
  def self.model_name
    @model_name ||= ActiveModel::Name.new(self, nil, name.demodulize)
  end
end
