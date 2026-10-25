require "rails_helper"

# Front-end contracts for the public catalog: on-page SEO basics and the
# accessibility basics that can be asserted from the rendered HTML.
RSpec.describe "Public catalog SEO and accessibility", type: :request do
  describe "on-page SEO" do
    it "gives every page its own title and meta description" do
      category = create(:category, name: "Jarrones")
      create(:product, category: category, name: "Jarrón artesanal", description: "Hecho a mano")

      get root_path
      landing_title = response.body[%r{<title>(.*?)</title>}m, 1]
      landing_description = response.body[/name="description" content="([^"]*)"/, 1]

      get product_path("jarron-artesanal")
      product_title = response.body[%r{<title>(.*?)</title>}m, 1]
      product_description = response.body[/name="description" content="([^"]*)"/, 1]

      expect(landing_title).to be_present
      expect(product_title).to be_present
      expect(product_title).not_to eq(landing_title)
      expect(landing_description).to be_present
      expect(product_description).to be_present
      expect(product_description).not_to eq(landing_description)
    end

    it "adds a self-referencing canonical URL to every page" do
      create(:category, name: "Jarrones")
      create(:product, category: create(:category), name: "Jarrón artesanal")

      get products_path

      expect(response.body).to include(%(<link rel="canonical" href="http://www.example.com/products">))
    end

    it "exposes Open Graph data for social sharing" do
      create(:product, name: "Jarrón artesanal")

      get product_path("jarron-artesanal")

      expect(response.body).to include('property="og:title"')
      expect(response.body).to include('property="og:description"')
      expect(response.body).to include('property="og:type" content="product"')
      expect(response.body).to include('property="og:url"')
    end

    it "describes the product with Product structured data" do
      product = create(:product, name: "Jarrón artesanal", description: "Hecho a mano", price_cents: 4500)
      create(:variant, product: product, name: "Única", stock: 3)

      get product_path(product.slug)

      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"Product"')
      expect(response.body).to include('"priceCurrency":"EUR"')
      expect(response.body).to include('"lowPrice":"45.0"')
      expect(response.body).to include('"offerCount":1')
      expect(response.body).to include("InStock")
    end

    it "marks sold out products as unavailable in the structured data" do
      product = create(:product, name: "Jarrón artesanal", price_cents: 4500)
      create(:variant, product: product, name: "Única", stock: 0)

      get product_path(product.slug)

      expect(response.body).to include("OutOfStock")
    end

    it "serves a sitemap with the catalog URLs" do
      category = create(:category, name: "Jarrones")
      product = create(:product, category: category, name: "Jarrón artesanal")

      get "/sitemap.xml"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product_path(product.slug))
      expect(response.body).to include(category_path(category.slug))
    end

    it "points robots.txt to the sitemap" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sitemap:")
    end

    it "serves a PWA manifest with the brand name and the app icons" do
      get "/manifest.json"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('"name": "Silvalde Hogar"')
      expect(response.body).to include('"short_name": "Silvalde Hogar"')
      expect(response.body).to include('"src": "/logo.png')
    end

    it "links the manifest and the brand icons on every page" do
      get root_path

      expect(response.body).to include('rel="manifest"')
      expect(response.body).to include('href="/manifest"')
      expect(response.body).to include('href="/logo.svg')
      expect(response.body).to include('href="/logo.png')
    end

    it "versions the brand icons so browsers do not keep a stale logo" do
      get root_path

      expect(response.body).to include('/logo.png?v=')
      expect(response.body).to include('/logo.svg?v=')
    end
  end

  describe "accessibility" do
    it "flags a discounted variant as an offer" do
      product = create(:product, name: "Set de velas", price_cents: 2400)
      create(:variant, product: product, name: "Pack de 4", price_cents: 1800)

      get product_path(product.slug)

      expect(response.body).to include("Oferta")
    end

    it "offers a skip link and a main landmark" do
      get root_path

      expect(response.body).to include('href="#main-content"')
      expect(response.body).to include('id="main-content"')
      expect(response.body).to include("<main")
    end

    it "has exactly one main heading per page" do
      create(:product, name: "Jarrón artesanal")

      get product_path("jarron-artesanal")

      expect(response.body.scan(/<h1[^>]*>/).size).to eq(1)
    end

    it "gives product images a descriptive alternative text" do
      product = create(:product, name: "Jarrón artesanal")
      product.images.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/images/red-square.jpg")),
        filename: "red-square.jpg"
      )

      get product_path(product.slug)

      expect(response.body).to include('alt="Jarrón artesanal"')
    end

    it "labels the search field" do
      get products_path

      expect(response.body).to include("<label")
      expect(response.body).to include('name="q"')
    end

    it "declares the page language" do
      get root_path

      expect(response.body).to include('<html lang="es"')
    end
  end

  describe "footer" do
    it "links to the categories on pages that don't load them explicitly" do
      category = create(:category, name: "Jarrones")
      create(:product, name: "Jarrón artesanal")

      get products_path

      expect(response.body).to include(category_path(category.slug))
      expect(response.body).to include("Jarrones")
    end
  end

  describe "header" do
    it "shows the brand logo next to the site name" do
      get root_path

      expect(response.body).to include('src="/logo.png')
      expect(response.body).to include("Silvalde Hogar")
    end

    it "marks the brand logo as decorative so screen readers skip it" do
      get root_path

      expect(response.body).to include('<img alt="" aria-hidden="true"')
    end
  end
end
