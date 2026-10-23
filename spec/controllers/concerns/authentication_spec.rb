require "rails_helper"

RSpec.describe Authentication, type: :controller do
  # Build an anonymous controller that includes the concern under test
  # and exposes the protected actions we want to drive.
  controller(ApplicationController) do
    include Authentication

    def index
      render plain: "ok-#{Current.user&.id || "anon"}"
    end

    def protected_action
      render plain: "secret"
    end

    def sign_out
      terminate_session
      render plain: "signed-out"
    end
  end

  before do
    routes.draw do
      get "index" => "anonymous#index"
      get "protected" => "anonymous#protected_action"
      get "sign_out" => "anonymous#sign_out"
      get "login" => "anonymous#index", as: :login # login_path used by require_authentication
    end
    # Re-apply the require_authentication filter on the test controller.
    controller_class = controller.class
    controller_class.before_action :require_authentication, only: :protected_action
  end

  let(:user) { create(:user) }

  describe "current_user" do
    it "is nil when no session cookie is present" do
      get :index
      expect(response.body).to eq("ok-anon")
    end

    it "is the user when a valid session cookie is present" do
      session_record, plaintext = Auth::Session.build_for(user)
      session_record.save!
      cookies.signed[:session_token] = plaintext

      get :index
      expect(response.body).to eq("ok-#{user.id}")
    end

    it "ignores an invalid session cookie" do
      cookies.signed[:session_token] = "garbage"

      get :index
      expect(response.body).to eq("ok-anon")
    end

    it "ignores an expired session cookie" do
      session_record, plaintext = Auth::Session.build_for(user)
      session_record.update!(expires_at: 1.minute.ago)
      session_record.save!
      cookies.signed[:session_token] = plaintext

      get :index
      expect(response.body).to eq("ok-anon")
    end
  end

  describe "user_signed_in?" do
    it "is false without a session" do
      get :index
      expect(response.body).to eq("ok-anon")
    end

    it "is true with a valid session" do
      session_record, plaintext = Auth::Session.build_for(user)
      session_record.save!
      cookies.signed[:session_token] = plaintext

      get :index
      expect(response.body).to eq("ok-#{user.id}")
    end
  end

  describe "require_authentication" do
    it "redirects to login_path when not signed in" do
      get :protected_action
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq(I18n.t("authentication.flash.sign_in_required"))
    end

    it "lets the request through when signed in" do
      session_record, plaintext = Auth::Session.build_for(user)
      session_record.save!
      cookies.signed[:session_token] = plaintext

      get :protected_action
      expect(response.body).to eq("secret")
    end
  end

  describe "terminate_session" do
    it "destroys the session and clears the cookie" do
      session_record, plaintext = Auth::Session.build_for(user)
      session_record.save!
      cookies.signed[:session_token] = plaintext

      get :index
      expect(Auth::Session.find_by(id: session_record.id)).to be_present

      get :sign_out

      expect(response.body).to eq("signed-out")
      expect(Auth::Session.find_by(id: session_record.id)).to be_nil
    end
  end

  describe "remember_me" do
    it "creates a session with a 30-day expiration when remember_me is true" do
      controller.send(:start_new_session_for, user, remember_me: true)
      expect(Current.session.expires_at).to be_within(2.seconds).of(30.days.from_now)
    end

    it "creates a session with a 1-day expiration by default" do
      controller.send(:start_new_session_for, user)
      expect(Current.session.expires_at).to be_within(2.seconds).of(1.day.from_now)
    end
  end
end
