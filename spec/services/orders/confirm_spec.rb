require "rails_helper"

RSpec.describe Orders::Confirm do
  describe ".call" do
    it "moves a pending order to confirmed when the payment lands" do
      order = create(:order)

      result = described_class.call(order: order)

      expect(result).to eq(order)
      expect(order.reload.state).to eq("confirmed")
    end

    it "records the move in the status history" do
      order = create(:order)

      described_class.call(order: order)

      change = order.status_changes.sole
      expect(change.from_state).to eq("pending")
      expect(change.to_state).to eq("confirmed")
      expect(change.user).to be_nil
      expect(change.manual).to be(false)
    end

    it "keeps who confirmed the order" do
      user = create(:user)
      order = create(:order)

      described_class.call(order: order, user: user)

      expect(order.status_changes.sole.user).to eq(user)
    end

    describe "an order that is not pending cannot be confirmed" do
      %w[confirmed ready_for_pickup picked_up shipped delivered cancelled].each do |state|
        it "refuses a #{state} order and touches nothing" do
          order = order_in(state)

          expect { described_class.call(order: order) }
            .to raise_error(AASM::InvalidTransition)

          expect(order.reload.state).to eq(state)
          expect(Orders::StatusChange.count).to eq(0)
        end
      end
    end

    it "never confirms twice from a stale tab" do
      order = create(:order)
      stale_tab = Orders::Order.find(order.id) # another admin tab, older snapshot

      described_class.call(order: order)

      expect { described_class.call(order: stale_tab) }
        .to raise_error(AASM::InvalidTransition)
      expect(order.reload.status_changes.count).to eq(1)
    end
  end
end
