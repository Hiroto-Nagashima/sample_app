class PasswordResetsController < ApplicationController
  before_action :get_user,   only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  
  def new
  end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash.now[:danger] = "Email address not found"
      render 'new'
    end
  end

  def edit
  end
  
  def update
    if params[:user][:password].empty?                 #新しいパスワードが空文字列になっていないか（ユーザー情報の編集ではOKだった）
      @user.errors.add(:password, :blank)
      render 'edit'
    elsif @user.update(user_params)                     # 新しいパスワードが正しければ、更新する
      log_in @user
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      render 'edit'                                     #無効なパスワードであれば失敗させる（失敗した理由も表示する）
    end
  end

# 　editアクションとupdateアクションのどちらの場合も正当な@userが存在する必要がある。
# 　アクションに飛ぶ前に@userが存在するか確認
  private
    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    def get_user
      @user = User.find_by(email: params[:email])
    end

    # 正しいユーザーかどうか確認する
    def valid_user
      unless (@user && @user.activated? &&
              @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end
    
    # トークンが期限切れかどうか確認する
    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password reset has expired."
        redirect_to new_password_reset_url
      end
    end
end
