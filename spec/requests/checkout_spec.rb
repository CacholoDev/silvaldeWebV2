require "rails_helper"

RSpec.describe "Checkout", type: :request do
  let(:variant) { create(:variant, price_cents: 1500, stock: 5) }

  def fill_cart(quantity: 2)
    post cart_items_path, params: { variant_id: variant.id, quantity: quantity }
  end

  def checkout_params(overrides = {})
    {
      order: {
        contact_name: "Ana Iglesias", contact_email: "ana@example.com", contact_phone: "600 123 456",
        pickup_store: "bertamirans", payment_method: "bank_transfer"
      }
    }.deep_merge(overrides)
  end

  describe "GET /checkout" do
    it "shows the order form" do
      fill_cart

      get checkout_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("checkout.page_title"))
    end

    it "the cart page links to the checkout" do
      fill_cart

      get cart_path

      expect(response.body).to include(%(href="#{checkout_path}"))
    end

    it "prefills the contact from the signed-in account" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "secret123" }
      fill_cart

      get checkout_path

      expect(response.body).to include(user.name)
    end

    it "redirects an empty cart to the cart with a clear message" do
      get checkout_path

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq(I18n.t("checkout.empty_cart"))
    end
  end

  describe "POST /checkout" do
    it "creates the order, freezes prices, decrements stock and empties the cart" do
      fill_cart(quantity: 2)

      expect { post checkout_path, params: checkout_params }.to change(Orders::Order, :count).by(1)

      order = Orders::Order.sole
      expect(order.order_items.sole.unit_price_cents).to eq(1500)
      expect(variant.reload.stock).to eq(3)
      expect(Carts::CartItem.count).to eq(0)
      expect(response).to redirect_to(checkout_confirmation_path)
    end

    it "links the order to the signed-in account" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "secret123" }
      fill_cart

      post checkout_path, params: checkout_params

      expect(Orders::Order.sole.user).to eq(user)
    end

    it "creates a guest order without an account" do
      fill_cart

      post checkout_path, params: checkout_params

      expect(Orders::Order.sole).to be_guest
    end

    it "accepts a blank phone (the form sends an empty string)" do
      fill_cart

      post checkout_path, params: checkout_params(order: { contact_phone: "" })

      expect(Orders::Order.sole.contact_phone).to be_nil
    end

    it "keeps the payment choice checked when re-rendering the form with errors" do
      fill_cart

      post checkout_path, params: checkout_params(order: { contact_email: "no-es-un-email", payment_method: "bank_transfer" })

      radio = response.body[/<input[^>]*id="order_payment_method_bank_transfer"[^>]*>/]
      expect(radio).to include("checked")
    end

    it "a pay-in-store order is born confirmed" do
      fill_cart

      post checkout_path, params: checkout_params(order: { payment_method: "pay_in_store" })

      expect(Orders::Order.sole.state).to eq("confirmed")
    end

    it "re-renders the form with the errors and stores nothing when the data is invalid" do
      fill_cart

      post checkout_path, params: checkout_params(order: { contact_email: "no-es-un-email" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("activerecord.errors.models.order.attributes.contact_email.invalid"))
      expect(Orders::Order.count).to eq(0)
      expect(variant.reload.stock).to eq(5)
      expect(Carts::CartItem.count).to eq(1)
    end

    it "does not create a second order when the form is submitted twice" do
      fill_cart

      post checkout_path, params: checkout_params
      post checkout_path, params: checkout_params

      expect(Orders::Order.count).to eq(1)
      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq(I18n.t("checkout.empty_cart"))
    end

    it "rejects an empty cart with a clear message" do
      post checkout_path, params: checkout_params

      expect(Orders::Order.count).to eq(0)
      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq(I18n.t("checkout.empty_cart"))
    end
  end

  describe "GET /checkout/confirmation" do
    it "shows the placed order with its public number" do
      fill_cart
      post checkout_path, params: checkout_params

      get checkout_confirmation_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Orders::Order.sole.number)
      expect(response.body).to include(I18n.t("checkout.confirmation_title"))
    end

    it "keeps working on refresh" do
      fill_cart
      post checkout_path, params: checkout_params

      get checkout_confirmation_path
      get checkout_confirmation_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects home when there is no order to confirm" do
      get checkout_confirmation_path

      expect(response).to redirect_to(root_path)
    end
  end
end
