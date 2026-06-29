class AccountsController < ApplicationController
  def show
    @active_section = flash[:section] || "profile"
  end

  def update
    @active_section = params[:section] || "profile"

    if @active_section == "profile"
      if Current.user.update(profile_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: t("accounts.updated.profile")
      else
        render :show, status: :unprocessable_entity
      end
    elsif @active_section == "email"
      unless Current.user.authenticate(params[:current_password])
        Current.user.errors.add(:current_password, I18n.t("accounts.password_incorrect"))
        return render :show, status: :unprocessable_entity
      end
      if Current.user.update(email_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: t("accounts.updated.email")
      else
        render :show, status: :unprocessable_entity
      end
    elsif @active_section == "language"
      if Current.user.update(locale_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: t("settings.language_updated")
      else
        render :show, status: :unprocessable_entity
      end
    elsif @active_section == "password"
      unless Current.user.authenticate(params[:current_password])
        Current.user.errors.add(:current_password, I18n.t("accounts.password_incorrect"))
        return render :show, status: :unprocessable_entity
      end
      if params[:password].blank?
        Current.user.errors.add(:password, :blank)
        return render :show, status: :unprocessable_entity
      end
      if Current.user.update(password_params)
        flash[:section] = @active_section
        redirect_to account_path(anchor: @active_section), notice: t("accounts.updated.password")
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  def destroy
    unless params[:confirmation] == "DELETE"
      redirect_to account_path, alert: t("accounts.delete_confirmation_failed")
      return
    end

    user = Current.user
    terminate_session
    user.destroy
    redirect_to root_path, notice: t("accounts.deleted")
  end

  def destroy_avatar
    Current.user.avatar.purge
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = t("accounts.avatar_removed")
      end
      format.html do
        flash[:section] = "profile"
        redirect_to account_path(anchor: "profile"), notice: t("accounts.avatar_removed")
      end
    end
  end

  private

  def profile_params
    p = params.permit(:display_name, :avatar)
    p.delete(:avatar) if p[:avatar].blank?
    p
  end

  def locale_params
    params.permit(:locale)
  end

  def email_params
    params.permit(:email_address)
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
