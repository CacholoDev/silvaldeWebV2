require "rails_helper"

RSpec.describe "Landing page", type: :request do
  it "shows the shop intro with the catalog" do
    category = create(:category, name: "Jarrones")
    product = create(:product, category: category, name: "Jarrón artesanal")

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Jarrón artesanal")
    expect(response.body).to include("Jarrones")
    expect(response.body).not_to include("Translation missing")
  end

  it "links to the catalog pages" do
    category = create(:category, name: "Jarrones")
    product = create(:product, category: category, name: "Jarrón artesanal")

    get root_path

    expect(response.body).to include(product_path(product.slug))
    expect(response.body).to include(category_path(category.slug))
    expect(response.body).to include(products_path)
  end
end
