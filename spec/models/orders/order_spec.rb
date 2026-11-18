require "rails_helper"

RSpec.describe Orders::Order, type: :model do
  describe "validations" do
    subject { build(:order) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a contact name" do
      order = build(:order, contact_name: nil)
      expect(order).not_to be_valid
      expect(order.errors[:contact_name]).to include("El nombre de contacto no puede estar vacío.")
    end

    it "rejects a contact name longer than the column" do
      order = build(:order, contact_name: "a" * 256)
      expect(order).not_to be_valid
      expect(order.errors[:contact_name]).to include("El nombre de contacto es demasiado largo (máximo 255 caracteres).")
    end

    it "requires a contact email" do
      order = build(:order, contact_email: nil)
      expect(order).not_to be_valid
      expect(order.errors[:contact_email]).to include("El email de contacto no puede estar vacío.")
    end

    it "rejects a malformed contact email" do
      order = build(:order, contact_email: "no-es-un-email")
      expect(order).not_to be_valid
      expect(order.errors[:contact_email]).to include("El formato del email de contacto no es válido.")
    end

    it "rejects a contact email longer than the column" do
      order = build(:order, contact_email: "#{"a" * 244}@example.com")
      expect(order).not_to be_valid
      expect(order.errors[:contact_email]).to include("El email de contacto es demasiado largo (máximo 255 caracteres).")
    end

    it "allows a blank phone (it is optional)" do
      order = build(:order, contact_phone: nil)
      expect(order).to be_valid
    end

    it "rejects a malformed phone" do
      order = build(:order, contact_phone: "llamame pronto")
      expect(order).not_to be_valid
      expect(order.errors[:contact_phone]).to include("El formato del teléfono no es válido.")
    end

    it "requires a pickup store" do
      order = build(:order, pickup_store: nil)
      expect(order).not_to be_valid
      expect(order.errors[:pickup_store]).to include("La tienda de recogida no puede estar vacía.")
    end

    it "accepts the Bertamirans and Noia stores" do
      expect(build(:order, pickup_store: "bertamirans")).to be_valid
      expect(build(:order, pickup_store: "noia")).to be_valid
    end

    it "rejects an unknown pickup store" do
      order = build(:order, pickup_store: "madrid")
      expect(order).not_to be_valid
      expect(order.errors[:pickup_store]).to include("La tienda de recogida no es válida.")
    end

    it "requires a payment method" do
      order = build(:order, payment_method: nil)
      expect(order).not_to be_valid
      expect(order.errors[:payment_method]).to include("El método de pago no puede estar vacío.")
    end

    it "accepts the offline payment methods" do
      expect(build(:order, payment_method: "bank_transfer")).to be_valid
      expect(build(:order, payment_method: "pay_in_store")).to be_valid
    end

    it "rejects an unknown payment method" do
      order = build(:order, payment_method: "magic_beans")
      expect(order).not_to be_valid
      expect(order.errors[:payment_method]).to include("El método de pago no es válido.")
    end

    it "requires a payment status" do
      order = build(:order, payment_status: nil)
      expect(order).not_to be_valid
      expect(order.errors[:payment_status]).to include("El estado del pago no puede estar vacío.")
    end

    it "accepts the known payment statuses" do
      expect(build(:order, payment_status: "pending")).to be_valid
      expect(build(:order, payment_status: "paid")).to be_valid
      expect(build(:order, payment_status: "refunded")).to be_valid
    end

    it "rejects an unknown payment status" do
      order = build(:order, payment_status: "maybe")
      expect(order).not_to be_valid
      expect(order.errors[:payment_status]).to include("El estado del pago no es válido.")
    end
  end

  describe "defaults" do
    it "starts with a pending payment" do
      expect(Orders::Order.new.payment_status).to eq("pending")
    end
  end

  describe "public number" do
    it "generates a public number when the order is created" do
      order = create(:order)
      expect(order.number).to be_present
    end

    it "follows the SV-XXXXXX format" do
      expect(create(:order).number).to match(Orders::Order::NUMBER_FORMAT)
    end

    it "generates a different number for each order" do
      first_order = create(:order)
      second_order = create(:order)

      expect(second_order.number).not_to eq(first_order.number)
    end

    it "does not derive the number from the sequential id" do
      order = create(:order)
      expect(order.number).to be_present
      expect(order.number).not_to eq("SV-#{order.id}")
    end

    it "keeps a number that was set explicitly" do
      order = create(:order, number: "SV-ABCDEF")
      expect(order.number).to eq("SV-ABCDEF")
    end

    it "rejects a malformed number" do
      order = build(:order, number: "SV-12")
      expect(order).not_to be_valid
      expect(order.errors[:number]).to include("El formato del número del pedido no es válido.")
    end

    it "rejects numbers with characters that are ambiguous when dictated" do
      order = build(:order, number: "SV-OIL012")
      expect(order).not_to be_valid
      expect(order.errors[:number]).to include("El formato del número del pedido no es válido.")
    end

    it "rejects a number already used by another order" do
      create(:order, number: "SV-ABCDEF")

      duplicate = build(:order, number: "SV-ABCDEF")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include("Ese número de pedido ya está en uso.")
    end
  end

  describe "state machine" do
    describe "initial state" do
      it "a bank-transfer order is born pending" do
        order = create(:order, payment_method: "bank_transfer")
        expect(order.state).to eq("pending")
      end

      it "a pay-in-store order is born confirmed (it pays on pickup, nothing to verify)" do
        order = create(:order, payment_method: "pay_in_store")
        expect(order.state).to eq("confirmed")
      end
    end

    describe "valid transitions" do
      it "confirms a pending order" do
        order = create(:order)
        order.confirm!
        expect(order.state).to eq("confirmed")
      end

      it "marks a confirmed pickup order as ready for pickup" do
        order = create(:order)
        order.confirm!
        order.mark_ready!
        expect(order.state).to eq("ready_for_pickup")
      end

      it "hands a ready order over to the customer" do
        order = create(:order, payment_method: "pay_in_store")
        order.mark_ready!
        order.mark_picked_up!
        expect(order.state).to eq("picked_up")
      end

      it "ships a confirmed shipping order" do
        order = create(:order, :shipping)
        order.confirm!
        order.ship!
        expect(order.state).to eq("shipped")
      end

      it "delivers a shipped order" do
        order = create(:order, :shipping)
        order.confirm!
        order.ship!
        order.deliver!
        expect(order.state).to eq("delivered")
      end

      it "cancels a pending order" do
        order = create(:order)
        order.cancel!
        expect(order.state).to eq("cancelled")
      end

      it "cancels a confirmed order" do
        order = create(:order, payment_method: "pay_in_store")
        order.cancel!
        expect(order.state).to eq("cancelled")
      end
    end

    describe "invalid transitions" do
      it "cannot prepare an order before it is confirmed" do
        order = create(:order)
        expect(order.may_mark_ready?).to be(false)
        expect { order.mark_ready! }.to raise_error(AASM::InvalidTransition)
      end

      it "cannot confirm an order twice" do
        order = create(:order, payment_method: "pay_in_store")
        expect(order.may_confirm?).to be(false)
      end

      it "cannot ship a pickup order" do
        order = create(:order, payment_method: "pay_in_store")
        expect(order.may_ship?).to be(false)
        expect { order.ship! }.to raise_error(AASM::InvalidTransition)
      end

      it "cannot prepare a shipping order for pickup" do
        order = create(:order, :shipping)
        order.confirm!
        expect(order.may_mark_ready?).to be(false)
      end

      it "cannot cancel an order that is already prepared" do
        order = create(:order, payment_method: "pay_in_store")
        order.mark_ready!
        expect(order.may_cancel?).to be(false)
        expect { order.cancel! }.to raise_error(AASM::InvalidTransition)
      end

      it "cannot cancel a shipped order" do
        order = create(:order, :shipping)
        order.confirm!
        order.ship!
        expect(order.may_cancel?).to be(false)
      end

      it "cannot cancel a picked-up order" do
        order = create(:order, payment_method: "pay_in_store")
        order.mark_ready!
        order.mark_picked_up!
        expect(order.may_cancel?).to be(false)
      end

      it "cannot move a cancelled order anywhere" do
        order = create(:order)
        order.cancel!
        expect(order.may_confirm?).to be(false)
      end

      it "cannot move a delivered order anywhere" do
        order = create(:order, :shipping)
        order.confirm!
        order.ship!
        order.deliver!
        expect(order.may_cancel?).to be(false)
        expect(order.may_ship?).to be(false)
      end

      it "rejects an unknown state" do
        order = build(:order)
        order.state = "bogus"
        expect(order).not_to be_valid
        expect(order.errors[:state]).to include("El estado del pedido no es válido.")
      end
    end
  end

  describe "delivery method" do
    it "accepts pickup and shipping" do
      expect(build(:order, delivery_method: "pickup")).to be_valid
      expect(build(:order, :shipping)).to be_valid
    end

    it "requires a delivery method" do
      order = build(:order, delivery_method: nil)
      expect(order).not_to be_valid
      expect(order.errors[:delivery_method]).to include("La forma de entrega no puede estar vacía.")
    end

    it "rejects an unknown delivery method" do
      order = build(:order, delivery_method: "drone")
      expect(order).not_to be_valid
      expect(order.errors[:delivery_method]).to include("La forma de entrega no es válida.")
    end

    it "lets a shipping order skip the pickup store" do
      expect(build(:order, :shipping)).to be_valid
    end

    it "rejects a pickup store on a shipping order" do
      order = build(:order, :shipping, pickup_store: "noia")
      expect(order).not_to be_valid
      expect(order.errors[:pickup_store]).to include("Un pedido con envío a domicilio no lleva tienda de recogida.")
    end
  end

  # The unique index and the NOT NULL live in the migration, below the app
  # validations. #save(validate: false) skips the model rules and hits the
  # database rules, proving the defence in depth is really there.
  describe "database constraints" do
    it "rejects a duplicated number at the database level" do
      create(:order, number: "SV-ABCDEF")

      duplicate = build(:order, number: "SV-ABCDEF")
      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects a missing number at the database level" do
      order = build(:order, number: nil)
      expect { order.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects an unknown state at the database level" do
      order = build(:order)
      order.state = "bogus"
      expect { order.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects a shipping order with a pickup store at the database level" do
      order = build(:order, :shipping, pickup_store: "noia")
      expect { order.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "#guest?" do
    it "is true without a user behind the order" do
      expect(build(:order, user: nil)).to be_guest
    end

    it "is false when the order belongs to an account" do
      order = build(:order, user: create(:user))
      expect(order).not_to be_guest
    end
  end

  describe "#paid?" do
    it "is true only when the payment status is paid" do
      expect(build(:order, payment_status: "paid")).to be_paid
      expect(build(:order, payment_status: "pending")).not_to be_paid
      expect(build(:order, payment_status: "refunded")).not_to be_paid
    end
  end

  describe "user association" do
    it "is optional: a guest order has no user" do
      order = build(:order, user: nil)
      expect(order).to be_valid
    end

    it "keeps the order but unlinks it when the account is deleted" do
      user = create(:user)
      order = create(:order, user: user)

      user.destroy

      expect(order.reload.user).to be_nil
    end
  end
end
