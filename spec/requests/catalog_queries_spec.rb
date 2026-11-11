require "rails_helper"

# The product cards show the first photo of each product: the attachments
# must be preloaded, not queried once per card (N+1).
RSpec.describe "Catalog image queries", type: :request do
  def create_product_with_photo(name)
    product = create(:product, name: name)
    create(:variant, product: product)
    product.images.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/images/red-square.jpg")),
      filename: "red-square.jpg"
    )
  end

  def attachment_queries
    count = 0
    counter = ->(*, payload) { count += 1 if payload[:sql].include?("active_storage_attachments") }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  it "does not add attachment queries for each extra product card" do
    create_product_with_photo("Producto 1")
    with_one = attachment_queries { get products_path }

    3.times { |i| create_product_with_photo("Producto extra #{i}") }
    with_four = attachment_queries { get products_path }

    expect(response).to have_http_status(:ok)
    expect(with_four).to eq(with_one)
  end
end
