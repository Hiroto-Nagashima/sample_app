module SessionsHelper
  # 渡されたユーザーでログインする
  def log_in(user)
    # sessionメソッドはハッシュのように扱える
    # ユーザーのブラウザ内の一時cookiesに暗号化済みのユーザーIDが自動で作成
    session[:user_id] = user.id
  end
  
  # 記憶トークンcookieに対応するユーザーを返す
  def current_user
    # 「（ユーザーIDにユーザーIDのセッションを代入した結果）ユーザーIDのセッションが存在すれば」
    if (user_id = session[:user_id])
      # ||= 数の値がnilなら変数に代入するが、nilでなければ代入しない（変数の値を変えない）
      # findと違ってfind_byはIDが無効な場合（=ユーザーが存在しない場合）にもメソッドは例外を発生せず、nilを返します。
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])       
      user = User.find_by(id: user_id)
      # ユーザーがデータベースにあり、かつ、認証に成功した場合にのみ
      # user.rbに定義したauthenticated?()メソッドは引数が二つ必要
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end
  
  def logged_in?
    # !　not演算子　current_userがnilでないならtrue,nilならfalse
    !current_user.nil?
  end
  
  # 永続的セッションを破棄する
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
  
  def log_out
    forget(current_user)
    session.delete(:user_id)
    # 本来はnilに設定する必要はないのですが、ここではセキュリティ上の死角を万が一にでも作り出さないためにあえてnilに設定しています。
    @current_user = nil
  end
  # ユーザーのセッションを永続的にする
  def remember(user)
    user.remember
    # user.idを暗号化
    cookies.permanent.signed[:user_id] = user.id
    # 記憶トークンに保存期限をつけてクッキーに保存
    cookies.permanent[:remember_token] = user.remember_token
  end
   # 渡されたユーザーがカレントユーザーであればtrueを返す
  def current_user?(user)
    user && user == current_user
  end
  
  # 記憶したURL（もしくはデフォルト値、引数）にリダイレクト
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # アクセスしようとしたURLを覚えておく
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end
