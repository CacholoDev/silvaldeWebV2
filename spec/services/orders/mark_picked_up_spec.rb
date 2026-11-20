require "rails_helper"

RSpec.describe Orders::MarkPickedUp do
  describe ".call" do
    it "hands the package over: ready_for_pickup becomes picked_up" do
      order = order_in("ready_for_pickup")

      result = described_class.call(order: order)

      expect(result).to eq(order)
      expect(order.reload.state).to eq("picked_up")
    end

    it "records the move in the status history" do
      order = order_in("ready_for_pickup")

      described_class.call(order: order)

      change = order.status_changes.sole
      expect(change.from_state).to eq("ready_for_pickup")
      expect(change.to_state).to eq("picked_up")
      expect(change.user).to be_nil
      expect(change.manual).to be(false)
    end

    it "keeps who handed the package over" do
      user = create(:user)
      order = order_in("ready_for_pickup")

      described_class.call(order: order, user: user)

      expect(order.status_changes.sole.user).to eq(user)
    end

    describe "only a prepared order can be handed over" do
      %w[pending confirmed shipped picked_up delivered cancelled].each do |state|
        it "refuses a #{state} order and touches nothing" do
          order = order_in(state)

          expect { described_class.call(order: order) }
            .to raise_error(AASM::InvalidTransition)

          expect(order.reload.state).to eq(state)
          expect(Orders::StatusChange.count).to eq(0)
        end
      end
    end

    it "never hands over twice from a stale tab" do
      order = order_in("ready_for_pickup")
      stale_tab = Orders::Order.find(order.id) # another admin tab, older snapshot

      described_class.call(order: order)

      expect { described_class.call(order: stale_tab) }
        .to raise_error(AASM::InvalidTransition)
      expect(order.reload.status_changes.count).to eq(1)
    end
  end
end
