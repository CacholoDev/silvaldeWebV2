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
