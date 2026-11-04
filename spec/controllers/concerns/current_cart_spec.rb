require "rails_helper"

RSpec.describe CurrentCart, type: :controller do
  # Build an anonymous controller that includes the concern under test and
  # exposes the actions we want to drive.
  controller(ApplicationController) do
    include Authentication
    include CurrentCart

    def show
      render plain: "cart-#{current_cart&.id || "none"}"
    end

    def attach
      self.current_cart = Carts::Search.find_active_cart(params[:cart_id])
      render plain: "attached"
    end

    def detach
      self.current_cart = nil
      render plain: "detached"
    end
  end

  before do
    routes.draw do
      get "show" => "anonymous#show"
      get "attach" => "anonymous#attach"
      get "detach" => "anonymous#detach"
    end
  end

  def sign_in(user)
    session_record, plaintext = Auth::Session.build_for(user)
    session_record.save!
    cookies.signed[:session_token] = plaintext
  end

  describe "#current_cart" do
    it "is nil when the session has no cart" do
      get :show

      expect(response.body).to eq("cart-none")
    end

    it "is the cart stored in the session" do
      cart = create(:cart)

      get :attach, params: { cart_id: cart.id }
      get :show

      expect(response.body).to eq("cart-#{cart.id}")
    end

    it "is nil when the session cart no longer exists" do
      cart = create(:cart)

      get :attach, params: { cart_id: cart.id }
      cart.destroy
      get :show

      expect(response.body).to eq("cart-none")
    end

    it "is nil when the session cart is expired" do
      cart = create(:cart)

      get :attach, params: { cart_id: cart.id }
      cart.update_column(:updated_at, 7.months.ago)
      get :show

      expect(response.body).to eq("cart-none")
    end

    it "falls back to the user's cart when the session has none" do
      user = create(:user)
      cart = create(:cart, user: user)
      sign_in(user)

      get :show

      expect(response.body).to eq("cart-#{cart.id}")
    end

    it "forgets a cart that belongs to another user" do
      owner = create(:user)
      foreign_cart = create(:cart, user: owner)
      user = create(:user)
      sign_in(user)

      get :attach, params: { cart_id: foreign_cart.id }
      get :show

      expect(response.body).to eq("cart-none")
    end
  end

  describe "#current_cart=" do
    it "stores the cart id in the session" do
      cart = create(:cart)

      get :attach, params: { cart_id: cart.id }

      expect(session[:cart_id]).to eq(cart.id)
    end

    it "clears the session cart" do
      cart = create(:cart)

      get :attach, params: { cart_id: cart.id }
      get :detach

      expect(session[:cart_id]).to be_nil
    end
  end
end
