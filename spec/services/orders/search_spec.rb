require "rails_helper"

RSpec.describe Orders::Search do
  describe ".orders_for" do
    it "returns the orders of that account, newest first" do
      user = create(:user)
      older = create(:order, user: user, created_at: 2.days.ago)
      newer = create(:order, user: user)

      expect(described_class.orders_for(user)).to eq([ newer, older ])
    end

    it "returns nothing for an account with no orders" do
      user = create(:user)

      expect(described_class.orders_for(user)).to be_empty
    end

    it "never returns the orders of another account" do
      ana = create(:user)
      bea = create(:user)
      create_list(:order, 3, user: bea)

      expect(described_class.orders_for(ana)).to be_empty
    end

    it "mixes in neither guest orders nor other accounts in a busy database" do
      ana = create(:user)
      mine = create_list(:order, 2, user: ana)
      create_list(:order, 3, user: create(:user))
      create_list(:order, 3, user: nil)

      expect(described_class.orders_for(ana)).to match_array(mine)
    end
  end

  describe ".find_order_by_number" do
    it "returns the order with that public number" do
      order = create(:order)

      expect(described_class.find_order_by_number(order.number)).to eq(order)
    end

    it "finds a guest order too (the shop looks it up over the phone)" do
      order = create(:order, user: nil)

      expect(described_class.find_order_by_number(order.number)).to eq(order)
    end

    it "returns nil for an unknown number" do
      create(:order)

      expect(described_class.find_order_by_number("SV-XXXXXX")).to be_nil
    end

    it "returns nil for a blank number without querying the database" do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(described_class.find_order_by_number(nil)).to be_nil
      end

      expect(queries).to be_empty
    end
  end

  describe ".find_order_by_signed_token" do
    it "returns the order behind a valid signed token" do
      order = create(:order)

      expect(described_class.find_order_by_signed_token(order.signed_id)).to eq(order)
    end

    it "returns nil for a tampered token" do
      order = create(:order)

      expect(described_class.find_order_by_signed_token("#{order.signed_id}tampered")).to be_nil
    end

    it "returns nil for the token of a deleted order" do
      order = create(:order)
      token = order.signed_id
      order.destroy

      expect(described_class.find_order_by_signed_token(token)).to be_nil
    end

    it "returns nil for a blank token without querying the database" do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(described_class.find_order_by_signed_token("")).to be_nil
      end

      expect(queries).to be_empty
    end
  end

  describe ".items_for" do
    it "returns the lines of that order" do
      order = create(:order)
      mine = create_list(:order_item, 2, order: order)

      expect(described_class.items_for(order)).to match_array(mine)
    end

    it "never returns the lines of another order" do
      order = create(:order)
      create_list(:order_item, 2, order: create(:order))

      expect(described_class.items_for(order)).to be_empty
    end
  end
end
