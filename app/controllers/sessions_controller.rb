class SessionsController < ApplicationController
  def new
  end
  
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    # Rubyではnilとfalse以外のすべてのオブジェクトは、真偽値ではtrueになる
    # ユーザーがデータベースにあり、かつ、認証に成功した場合にのみ
    if user && user.authenticate(params[:session][:password])
      # ユーザーログイン後にユーザー情報のページにリダイレクトする
      log_in user
      redirect_to user
    else
      # レンダリングが終わっているページで特別にフラッシュメッセージを表示することができます
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end
  
end
