class AccountActivationsController < ApplicationController
  # ユーザーは有効化ボタンをおす。つまりget アクションで更新をかける
  def edit
    # urlでemailを送ってきているのでここでキャッチ
    user = User.find_by(email: params[:email])
    # !user.activated?は、既に有効になっているユーザーを誤って再度有効化しないために必要です。
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end
end
