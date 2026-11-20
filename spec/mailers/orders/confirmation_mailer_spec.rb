require "rails_helper"

RSpec.describe Orders::ConfirmationMailer, type: :mailer do
  # The shop's payment details come from the environment; the examples set
  # their own values so the assertions never depend on the local .env.
  def with_env(vars)
    previous = vars.keys.to_h { |key| [ key, ENV[key] ] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  def decoded(mail)
    mail.parts.map { |part| part.body.decoded }.join
  end

  describe "#confirmation" do
    let(:order) { create(:order, payment_method: "bank_transfer") }
    let!(:item) { create(:order_item, order: order, quantity: 2) }

    it "sends to the contact email with the order number in the subject" do
      mail = described_class.with(order: order).confirmation

      expect(mail.to).to eq([ order.contact_email ])
      expect(mail.subject).to eq(I18n.t("orders.mailer.confirmation.subject", number: order.number))
    end

    it "includes the order summary with its lines and total" do
      mail = described_class.with(order: order).confirmation

      expect(decoded(mail)).to include(order.number)
      expect(decoded(mail)).to include(item.variant.product.name)
      expect(decoded(mail)).to include(Orders::OrderItemDecorator.new(item).formatted_subtotal)
    end

    it "includes the pickup store of a pickup order" do
      mail = described_class.with(order: order).confirmation

      expect(decoded(mail)).to include(I18n.t("checkout.stores.#{order.pickup_store}"))
    end

    it "includes the bank details for a bank-transfer order" do
      with_env("BANK_HOLDER" => "Silvalde Decoración",
               "BANK_IBAN" => "ES11 2222 3333 4444 5555 6666",
               "BIZUM_PHONE" => "600 123 456") do
        mail = described_class.with(order: order).confirmation

        expect(decoded(mail)).to include("Silvalde Decoración")
        expect(decoded(mail)).to include("ES11 2222 3333 4444 5555 6666")
        expect(decoded(mail)).to include("600 123 456")
      end
    end

    it "tells a pay-in-store order to pay at the counter, without bank details" do
      pay_at_store = create(:order, payment_method: "pay_in_store")

      mail = described_class.with(order: pay_at_store).confirmation

      expect(decoded(mail)).to include(I18n.t("orders.mailer.confirmation.pay_in_store"))
      expect(decoded(mail)).not_to include(I18n.t("orders.mailer.confirmation.bank_iban"))
    end

    it "speaks the language the customer used at checkout" do
      galician = create(:order, locale: "gl")

      mail = described_class.with(order: galician).confirmation

      expect(mail.subject).to eq(I18n.t("orders.mailer.confirmation.subject",
                                        number: galician.number, locale: :gl))
    end
  end
end
