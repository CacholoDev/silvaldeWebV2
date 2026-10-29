module ApplicationHelper
  # Path of a brand icon living in public/icons or public/svg, with a
  # cache-busting token so browsers pick up a new logo instead of keeping the
  # previously cached one.
  def brand_icon_path(name)
    folder = File.extname(name) == ".svg" ? "svg" : "icons"
    file = Rails.root.join("public", folder, name)
    token = File.exist?(file) ? File.mtime(file).to_i : 0

    "/#{folder}/#{name}?v=#{token}"
  end

  # Wraps a record in its presentation decorator (app/decorators).
  def decorate(record)
    case record
    when Catalog::Product then Catalog::ProductDecorator.new(record)
    when Catalog::Variant then Catalog::VariantDecorator.new(record)
    else record
    end
  end

  # Absolute URL of the current page without query string, so search
  # parameters never create duplicate indexable URLs.
  def canonical_page_url
    "#{request.base_url}#{request.path}"
  end

  # JSON-LD structured data for a product (schema.org Product with an
  # AggregateOffer, because a product can have several variants).
  def product_structured_data(product)
    prices = product.variants.filter_map(&:effective_price_cents)
    prices = [ product.price_cents ] if prices.empty?

    data = {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": product.name,
      "description": product.description,
      "url": product_url(product.slug),
      "sku": product.slug,
      "offers": {
        "@type": "AggregateOffer",
        "priceCurrency": "EUR",
        "lowPrice": (prices.min / 100.0).to_s,
        "highPrice": (prices.max / 100.0).to_s,
        "offerCount": product.variants.size,
        "availability": product.available? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock"
      }
    }

    images = product.images.map { |image| polymorphic_url(image, host: request.host, protocol: request.protocol) }
    data[:image] = images if images.any?

    data.to_json
  end

  # JSON-LD structured data for a list of products (schema.org ItemList).
  def product_list_structured_data(products)
    data = {
      "@context": "https://schema.org",
      "@type": "ItemList",
      "itemListElement": products.map.with_index do |product, index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "url": product_url(product.slug),
          "name": product.name
        }
      end
    }

    data.to_json
  end
end
