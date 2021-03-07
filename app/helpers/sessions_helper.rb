module SessionsHelper
  # 渡されたユーザーでログインする
  def log_in(user)
    # sessionメソッドはハッシュのように扱える
    # ユーザーのブラウザ内の一時cookiesに暗号化済みのユーザーIDが自動で作成
    session[:user_id] = user.id
  end
  
  def current_user
    if session[:user_id]
      # ||= 数の値がnilなら変数に代入するが、nilでなければ代入しない（変数の値を変えない）
      # findと違ってfind_byはIDが無効な場合（=ユーザーが存在しない場合）にもメソッドは例外を発生せず、nilを返します。
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end
  
  def logged_in?
    # !　not演算子　current_userがnilでないならtrue,nilならfalse
    !current_user.nil?
  end
  
  def log_out
    session.delete(:user_id)
    # 本来はnilに設定する必要はないのですが、ここではセキュリティ上の死角を万が一にでも作り出さないためにあえてnilに設定しています。
    @current_user = nil
  end
end
