require "rails_helper"

# End-to-end happy path of the cart with JavaScript on: the request specs
# cover the controllers, but only a browser proves that the Turbo Streams
# update the header counter and the feedback without a page reload.
RSpec.describe "Shopping cart", type: :system do
  it "adds a product without reloading and shows it on the cart page" do
    product = create(:product, name: "Jarrón azul", price_cents: 4500)
    create(:variant, product: product, name: "Única", stock: 5)

    visit product_path(product.slug)
    fill_in I18n.t("cart.quantity"), with: 2
    click_button I18n.t("cart.add_to_cart")

    expect(page).to have_css("#cart_feedback", text: I18n.t("cart.added"))
    expect(page).to have_css("#cart_counter span[aria-hidden]", text: "2")

    within("#cart_counter") { click_link I18n.t("cart.title") }

    expect(page).to have_current_path(cart_path)
    expect(page).to have_text("Jarrón azul")
    expect(page).to have_text(/90[,.]00/)
  end
end
