require "rails_helper"

RSpec.describe Orders::StatusChange, type: :model do
  describe "validations" do
    subject { build(:order_status_change) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires an order" do
      change = build(:order_status_change, order: nil)
      expect(change).not_to be_valid
      expect(change.errors[:order]).to include("El pedido no puede estar vacío.")
    end

    it "requires a destination state" do
      change = build(:order_status_change, to_state: nil)
      expect(change).not_to be_valid
      expect(change.errors[:to_state]).to include("El estado de destino no puede estar vacío.")
    end

    it "rejects an unknown destination state" do
      change = build(:order_status_change, to_state: "bogus")
      expect(change).not_to be_valid
      expect(change.errors[:to_state]).to include("El estado de destino no es válido.")
    end

    it "allows a blank origin state (the row recording the birth of the order)" do
      change = build(:order_status_change, from_state: nil)
      expect(change).to be_valid
    end

    it "rejects an unknown origin state" do
      change = build(:order_status_change, from_state: "bogus")
      expect(change).not_to be_valid
      expect(change.errors[:from_state]).to include("El estado de origen no es válido.")
    end
  end

  describe "#automatic?" do
    it "is true when no user moved it (the system did)" do
      expect(build(:order_status_change, user: nil)).to be_automatic
    end

    it "is false when a user moved it" do
      change = build(:order_status_change, user: create(:user))
      expect(change).not_to be_automatic
    end
  end

  # The CHECK constraints live in the migration, below the app validations.
  # #save(validate: false) skips the model rules and hits the database rules,
  # proving the defence in depth is really there.
  describe "database constraints" do
    it "rejects an unknown destination state at the database level" do
      change = build(:order_status_change, to_state: "bogus")
      expect { change.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects an unknown origin state at the database level" do
      change = build(:order_status_change, from_state: "bogus")
      expect { change.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
