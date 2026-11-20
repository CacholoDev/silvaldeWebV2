require "rails_helper"

RSpec.describe Orders::Cancel do
  describe ".call" do
    describe "an order on its way can be cancelled" do
      it "moves a pending order to cancelled" do
        order = create(:order)

        result = described_class.call(order: order)

        expect(result).to eq(order)
        expect(order.reload.state).to eq("cancelled")
      end

      it "cancels a confirmed order too" do
        order = order_in("confirmed")

        described_class.call(order: order)

        expect(order.reload.state).to eq("cancelled")
      end

      it "returns to each variant the stock of its line" do
        variant_a = create(:variant, stock: 7)
        variant_b = create(:variant, stock: 2)
        order = create(:order)
        create(:order_item, order: order, variant: variant_a, quantity: 2)
        create(:order_item, order: order, variant: variant_b, quantity: 1)

        described_class.call(order: order)

        expect(variant_a.reload.stock).to eq(9)
        expect(variant_b.reload.stock).to eq(3)
      end

      it "records the move in the status history" do
        order = create(:order)

        described_class.call(order: order)

        change = order.status_changes.sole
        expect(change.from_state).to eq("pending")
        expect(change.to_state).to eq("cancelled")
        expect(change.user).to be_nil
        expect(change.manual).to be(false)
      end

      it "keeps who cancelled the order" do
        user = create(:user)
        order = create(:order)

        described_class.call(order: order, user: user)

        expect(order.status_changes.sole.user).to eq(user)
      end
    end

    describe "a final order cannot be cancelled" do
      # Once prepared, shipped, picked up, delivered or cancelled there is no
      # way back: the state machine refuses and nothing is touched, stock
      # included.
      %w[ready_for_pickup shipped picked_up delivered cancelled].each do |state|
        it "refuses a #{state} order and touches nothing" do
          variant = create(:variant, stock: 7)
          order = order_in(state)
          create(:order_item, order: order, variant: variant, quantity: 2)

          expect { described_class.call(order: order) }
            .to raise_error(AASM::InvalidTransition)

          expect(order.reload.state).to eq(state)
          expect(variant.reload.stock).to eq(7)
          expect(Orders::StatusChange.count).to eq(0)
        end
      end
    end

    describe "rollback" do
      it "keeps stock, state and history untouched when the move fails midway" do
        variant = create(:variant, stock: 7)
        order = create(:order)
        create(:order_item, order: order, variant: variant, quantity: 2)
        # Nothing fails on its own on the last step, so a stub triggers the
        # breakdown; the assertions below are on real database state.
        allow(Orders::StatusChange).to receive(:create!).and_raise("the database broke down")

        expect { described_class.call(order: order) }.to raise_error("the database broke down")

        expect(order.reload.state).to eq("pending")
        expect(variant.reload.stock).to eq(7)
        expect(Orders::StatusChange.count).to eq(0)
      end
    end

    describe "concurrency" do
      it "never returns the stock twice when two cancellations race" do
        variant = create(:variant, stock: 7)
        order = create(:order)
        create(:order_item, order: order, variant: variant, quantity: 2)
        stale_tab = Orders::Order.find(order.id) # another admin tab, older snapshot

        described_class.call(order: order)

        expect { described_class.call(order: stale_tab) }
          .to raise_error(AASM::InvalidTransition)
        expect(variant.reload.stock).to eq(9) # 7 + 2, only once
      end
    end
  end
end
