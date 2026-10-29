module Catalog
  class VariantDecorator < ApplicationDecorator
    def formatted_price
      euros(effective_price_cents)
    end

    def availability_label
      available? ? I18n.t("catalog.products.available") : I18n.t("catalog.products.sold_out")
    end

    # True when the variant is priced below the product price (an offer).
    def on_offer?
      price_cents.present? && price_cents < product.price_cents
    end
  end
end
