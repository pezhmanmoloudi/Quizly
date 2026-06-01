class AccountsController < ApplicationController
  def show
    @active_section = flash[:section] || "profile"
  end

  def update
    @active_section = params[:email_address].present? ? "email" : "password"

    unless Current.user.authenticate(params[:current_password])
      flash.now[:alert] = "Current password is incorrect."
      return render :show, status: :unprocessable_entity
    end

    if Current.user.update(account_params)
      redirect_to account_path, notice: "Account updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.permit(:email_address, :password, :password_confirmation)
          .reject { |_, v| v.blank? }
  end
end
