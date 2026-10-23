module Users
  class ProfilesController < ApplicationController
    require_authentication

    def show
      @user = current_user
    end

    def edit
      @user = current_user
    end

    def update
      @user = UpdateProfile.call(current_user, profile_params)

      if @user.errors.any?
        render :edit, status: :unprocessable_content
      else
        redirect_to profile_path, notice: I18n.t("profiles.flash.updated")
      end
    end

    private

    def profile_params
      params.require(:user).permit(:name, :email)
    end
  end
end
