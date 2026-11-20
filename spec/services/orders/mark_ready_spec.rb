require "rails_helper"

RSpec.describe Orders::MarkReady do
  describe ".call" do
    it "moves a confirmed pickup order to ready_for_pickup" do
      order = order_in("confirmed")

      result = described_class.call(order: order)

      expect(result).to eq(order)
      expect(order.reload.state).to eq("ready_for_pickup")
    end

    it "records the move in the status history" do
      order = order_in("confirmed")

      described_class.call(order: order)

      change = order.status_changes.sole
      expect(change.from_state).to eq("confirmed")
      expect(change.to_state).to eq("ready_for_pickup")
      expect(change.user).to be_nil
      expect(change.manual).to be(false)
    end

    it "keeps who prepared the order" do
      user = create(:user)
      order = order_in("confirmed")

      described_class.call(order: order, user: user)

      expect(order.status_changes.sole.user).to eq(user)
    end

    describe "only a confirmed pickup order can be prepared" do
      %w[pending ready_for_pickup picked_up shipped delivered cancelled].each do |state|
        it "refuses a #{state} order and touches nothing" do
          order = order_in(state)

          expect { described_class.call(order: order) }
            .to raise_error(AASM::InvalidTransition)

          expect(order.reload.state).to eq(state)
          expect(Orders::StatusChange.count).to eq(0)
        end
      end

      it "refuses a shipping order (it will be shipped, not picked up)" do
        order = create(:order, :shipping)
        order.confirm!

        expect { described_class.call(order: order) }
          .to raise_error(AASM::InvalidTransition)

        expect(order.reload.state).to eq("confirmed")
        expect(Orders::StatusChange.count).to eq(0)
      end
    end

    it "never prepares twice from a stale tab" do
      order = order_in("confirmed")
      stale_tab = Orders::Order.find(order.id) # another admin tab, older snapshot

      described_class.call(order: order)

      expect { described_class.call(order: stale_tab) }
        .to raise_error(AASM::InvalidTransition)
      expect(order.reload.status_changes.count).to eq(1)
    end
  end
end
