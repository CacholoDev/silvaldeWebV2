# Preview at http://localhost:3100/rails/mailers/orders/confirmation_mailer
# (development, with the seeded catalog).
module Orders
  class ConfirmationMailerPreview < ActionMailer::Preview
    def confirmation
      order = Orders::Order.new(
        contact_name: "Ana Iglesias", contact_email: "ana@example.com",
        pickup_store: "bertamirans", payment_method: "bank_transfer",
        number: "SV-DEMO42", state: "pending", locale: "es"
      )
      variant = Catalog::Variant.first
      order.order_items.build(variant: variant, quantity: 2,
                              unit_price_cents: variant&.effective_price_cents || 1200)

      Orders::ConfirmationMailer.with(order: order).confirmation
    end
  end
end
