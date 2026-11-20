require "rails_helper"

RSpec.describe Orders::Checkout do
  let(:contact) do
    { contact_name: "Ana Iglesias", contact_email: "ana@example.com", contact_phone: "600 123 456",
      pickup_store: "bertamirans", payment_method: "bank_transfer" }
  end

  def checkout(cart, **overrides)
    described_class.call(cart: cart, **contact.merge(overrides))
  end

  describe ".call" do
    describe "success" do
      it "creates the order with its lines at the frozen catalog prices" do
        variant = create(:variant, price_cents: 1200, stock: 10)
        cart = create(:cart)
        create(:cart_item, cart: cart, variant: variant, quantity: 2)

        order = checkout(cart)

        expect(order).to be_persisted
        expect(order.order_items.size).to eq(1)
        item = order.order_items.first
        expect(item.variant).to eq(variant)
        expect(item.quantity).to eq(2)
        expect(item.unit_price_cents).to eq(1200)

        variant.update!(price_cents: 999)
        expect(item.reload.unit_price_cents).to eq(1200)
      end

      it "decrements the stock of each variant" do
        variant = create(:variant, stock: 10)
        cart = create(:cart)
        create(:cart_item, cart: cart, variant: variant, quantity: 3)

        checkout(cart)

        expect(variant.reload.stock).to eq(7)
      end

      it "empties the cart" do
        cart = create(:cart)
        create(:cart_item, cart: cart)

        checkout(cart)

        expect(cart.cart_items).to be_empty
      end

      it "records the birth of the order in the status history" do
        cart = create(:cart)
        create(:cart_item, cart: cart)

        order = checkout(cart)

        change = order.status_changes.sole
        expect(change.from_state).to be_nil
        expect(change.to_state).to eq("pending")
        expect(change.user).to be_nil
      end

      it "a pay-in-store order is born confirmed (and its history says so)" do
        cart = create(:cart)
        create(:cart_item, cart: cart)

        order = checkout(cart, payment_method: "pay_in_store")

        expect(order.state).to eq("confirmed")
        expect(order.status_changes.sole.to_state).to eq("confirmed")
      end

      it "keeps the account behind the order" do
        user = create(:user)
        cart = create(:cart)
        create(:cart_item, cart: cart)

        order = checkout(cart, user: user)

        expect(order.user).to eq(user)
      end

      it "creates a guest order without an account" do
        cart = create(:cart)
        create(:cart_item, cart: cart)

        order = checkout(cart)

        expect(order).to be_guest
      end

      it "keeps the language used at checkout for its emails" do
        cart = create(:cart)
        create(:cart_item, cart: cart)

        order = checkout(cart, locale: "gl")

        expect(order.locale).to eq("gl")
      end

      it "sends the confirmation email once the order is placed" do
        cart = create(:cart)
        create(:cart_item, cart: cart)

        expect { checkout(cart) }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.last.to).to eq([ "ana@example.com" ])
      end
    end

    describe "failures save nothing" do
      it "sends no email when the checkout fails" do
        cart = create(:cart)

        expect { checkout(cart) }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "rejects an empty cart" do
        cart = create(:cart)

        order = checkout(cart)

        expect(order).not_to be_persisted
        expect(order.errors[:base]).to include("El carrito está vacío.")
        expect { checkout(cart) }.not_to change(Orders::Order, :count)
      end

      it "reports the line without stock and saves nothing" do
        variant = create(:variant, stock: 0)
        cart = create(:cart)
        create(:cart_item, cart: cart, variant: variant, quantity: 1)

        order = checkout(cart)

        expect(order).not_to be_persisted
        expect(order.errors[:base]).to include("No hay stock suficiente de «#{variant.name}».")
        expect(Orders::Order.count).to eq(0)
        expect(variant.reload.stock).to eq(0)
      end

      it "rolls back the whole cart when one line lacks stock" do
        ok_variant = create(:variant, stock: 10)
        empty_variant = create(:variant, stock: 0)
        cart = create(:cart)
        create(:cart_item, cart: cart, variant: ok_variant, quantity: 2)
        create(:cart_item, cart: cart, variant: empty_variant, quantity: 1)

        order = checkout(cart)

        expect(order).not_to be_persisted
        expect(ok_variant.reload.stock).to eq(10)
        expect(cart.cart_items.size).to eq(2)
      end

      it "rolls back its writes even when called inside another transaction" do
        ok_variant = create(:variant, stock: 10)
        empty_variant = create(:variant, stock: 0)
        cart = create(:cart)
        create(:cart_item, cart: cart, variant: ok_variant, quantity: 2)
        create(:cart_item, cart: cart, variant: empty_variant, quantity: 1)

        order = nil
        ActiveRecord::Base.transaction(joinable: true) do
          order = checkout(cart)
        end

        expect(order).not_to be_persisted
        expect(ok_variant.reload.stock).to eq(10)
      end

      it "returns the order with its validation errors when contact data is invalid" do
        variant = create(:variant, stock: 10)
        cart = create(:cart)
        create(:cart_item, cart: cart, variant: variant, quantity: 1)

        order = checkout(cart, contact_email: "no-es-un-email")

        expect(order).not_to be_persisted
        expect(order.errors[:contact_email]).to include("El formato del email de contacto no es válido.")
        expect(variant.reload.stock).to eq(10)
        expect(cart.cart_items.size).to eq(1)
      end
    end

    describe "concurrency" do
      it "does not sell the last unit twice when two checkouts race" do
        variant = create(:variant, stock: 1)
        mine = create(:cart)
        create(:cart_item, cart: mine, variant: variant, quantity: 1)
        theirs = create(:cart)
        create(:cart_item, cart: theirs, variant: variant, quantity: 1)

        # The competing checkout lands right after we read our lines and
        # before we take the lock: the lock must reload the stock, catch the
        # steal and refuse our sale.
        reads = 0
        allow(Carts::Search).to receive(:items_for).and_wrap_original do |original, cart|
          result = original.call(cart)
          reads += 1
          checkout(theirs) if reads == 1
          result
        end

        order = checkout(mine)

        expect(order).not_to be_persisted
        expect(order.errors[:base]).to include("No hay stock suficiente de «#{variant.name}».")
        expect(variant.reload.stock).to eq(0)
        expect(Orders::Order.count).to eq(1)
      end
    end
  end
end
