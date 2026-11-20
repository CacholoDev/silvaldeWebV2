module Orders
  # "We got your order": sent right after checkout with the summary and how to
  # pay (bank transfer/Bizum details from the environment, or pay in store).
  # It speaks the language the customer used at checkout, stored in the order
  # itself (a background job has no session to remember it).
  class ConfirmationMailer < ApplicationMailer
    def confirmation
      @order = params[:order]
      @total_cents = Orders::Search.total_cents(@order)
      @payment_details = {
        holder: ENV.fetch("BANK_HOLDER", ""),
        iban: ENV.fetch("BANK_IBAN", ""),
        bizum_phone: ENV.fetch("BIZUM_PHONE", "")
      }

      I18n.with_locale(@order.locale) do
        mail(to: @order.contact_email,
             subject: t("orders.mailer.confirmation.subject", number: @order.number))
      end
    end
  end
end
