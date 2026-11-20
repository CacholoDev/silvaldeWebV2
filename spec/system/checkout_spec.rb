require "rails_helper"

RSpec.describe "Checkout front", type: :system do
  let!(:product) { create(:product, name: "Jarrón azul", price_cents: 4500) }
  let!(:variant) { create(:variant, product: product, name: "Única", stock: 5) }

  it "shows the order summary with the total before placing the order" do
    visit product_path(product.slug)
    fill_in I18n.t("cart.quantity"), with: 2
    click_button I18n.t("cart.add_to_cart")

    within("#cart_counter") { click_link I18n.t("cart.title") }
    click_link I18n.t("cart.checkout")

    expect(page).to have_current_path(checkout_path)
    expect(page).to have_text("Jarrón azul")
    expect(page).to have_text(I18n.t("checkout.summary_total"))
    expect(page).to have_text(/90[,.]00/)
  end
  it "places the order and shows the public number" do
    visit product_path(product.slug)
    fill_in I18n.t("cart.quantity"), with: 1
    click_button I18n.t("cart.add_to_cart")

    within("#cart_counter") { click_link I18n.t("cart.title") }
    click_link I18n.t("cart.checkout")
    fill_in I18n.t("checkout.name"), with: "Ana Iglesias"
    fill_in I18n.t("checkout.email"), with: "ana@example.com"
    select I18n.t("checkout.stores.noia"), from: I18n.t("checkout.pickup_select")
    choose I18n.t("checkout.payment_methods.bank_transfer")
    click_button I18n.t("checkout.submit")

    expect(page).to have_current_path(checkout_confirmation_path)
    expect(page).to have_text(I18n.t("checkout.confirmation_title"))
    expect(page).to have_text("SV-")
  end

  it "keeps the data and shows the errors when the data is wrong" do
    visit product_path(product.slug)
    click_button I18n.t("cart.add_to_cart")

    within("#cart_counter") { click_link I18n.t("cart.title") }
    click_link I18n.t("cart.checkout")
    fill_in I18n.t("checkout.name"), with: "Ana Iglesias"
    fill_in I18n.t("checkout.email"), with: "ana@example.com"
    fill_in I18n.t("checkout.phone"), with: "llamame"
    select I18n.t("checkout.stores.noia"), from: I18n.t("checkout.pickup_select")
    choose I18n.t("checkout.payment_methods.bank_transfer")
    click_button I18n.t("checkout.submit")

    expect(page).to have_content(I18n.t("checkout.errors_title", count: 1))
    expect(page).to have_field(I18n.t("checkout.name"), with: "Ana Iglesias")
    expect(page).to have_field(I18n.t("checkout.email"), with: "ana@example.com")
  end

  it "shows the error summary where the customer can see it" do
    visit product_path(product.slug)
    click_button I18n.t("cart.add_to_cart")

    within("#cart_counter") { click_link I18n.t("cart.title") }
    click_link I18n.t("cart.checkout")
    fill_in I18n.t("checkout.name"), with: "Ana Iglesias"
    fill_in I18n.t("checkout.email"), with: "ana@example.com"
    fill_in I18n.t("checkout.phone"), with: "llamame"
    select I18n.t("checkout.stores.noia"), from: I18n.t("checkout.pickup_select")
    choose I18n.t("checkout.payment_methods.bank_transfer")
    click_button I18n.t("checkout.submit")

    expect(page).to have_css("#form_errors")
    expect(page).to have_css("#form_errors", text: I18n.t("checkout.errors_title", count: 1))
  end
end
