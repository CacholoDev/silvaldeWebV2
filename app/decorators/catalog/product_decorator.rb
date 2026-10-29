module Catalog
  class ProductDecorator < ApplicationDecorator
    def formatted_price
      euros(price_cents)
    end

    def availability_label
      available? ? I18n.t("catalog.products.available") : I18n.t("catalog.products.sold_out")
    end

    def decorated_variants
      variants.map { |variant| VariantDecorator.new(variant) }
    end
  end
end
