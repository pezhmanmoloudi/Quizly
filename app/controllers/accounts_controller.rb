class AccountsController < ApplicationController
  def show
    @active_section = flash[:section] || "profile"
  end

  def update
    @active_section = params[:section] || "profile"

    if @active_section == "profile"
      if Current.user.update(profile_params)
        redirect_to account_path, notice: "Profile updated."
      else
        render :show, status: :unprocessable_entity
      end
    else
      unless Current.user.authenticate(params[:current_password])
        flash.now[:alert] = "Current password is incorrect."
        return render :show, status: :unprocessable_entity
      end
      if Current.user.update(email_password_params)
        redirect_to account_path, notice: "Account updated."
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  def destroy_avatar
    Current.user.avatar.purge
    redirect_to account_path, notice: "Profile photo removed."
  end

  private

  def profile_params
    p = params.permit(:display_name, :avatar)
    p.delete(:avatar) if p[:avatar].blank?
    p
  end

  def email_password_params
    params.permit(:email_address, :password, :password_confirmation)
          .reject { |_, v| v.blank? }
  end
end
