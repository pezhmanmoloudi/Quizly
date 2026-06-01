class AccountsController < ApplicationController
  def show
    @active_section = flash[:section] || "profile"
  end

  def update
    @active_section = params[:section] || "profile"

    if @active_section == "profile"
      if Current.user.update(profile_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: "Profile updated."
      else
        render :show, status: :unprocessable_entity
      end
    elsif @active_section == "email"
      unless Current.user.authenticate(params[:current_password])
        flash.now[:alert] = "Current password is incorrect."
        return render :show, status: :unprocessable_entity
      end
      if Current.user.update(email_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: "Email updated."
      else
        render :show, status: :unprocessable_entity
      end
    elsif @active_section == "password"
      unless Current.user.authenticate(params[:current_password])
        flash.now[:alert] = "Current password is incorrect."
        return render :show, status: :unprocessable_entity
      end
      if params[:password].blank?
        Current.user.errors.add(:password, :blank)
        return render :show, status: :unprocessable_entity
      end
      if Current.user.update(password_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: "Password updated."
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  def destroy_avatar
    Current.user.avatar.purge
    flash[:section] = "profile"
    redirect_to account_path(anchor: "profile"), notice: "Profile photo removed."
  end

  private

  def profile_params
    p = params.permit(:display_name, :avatar)
    p.delete(:avatar) if p[:avatar].blank?
    p
  end

  def email_params
    params.permit(:email_address)
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
