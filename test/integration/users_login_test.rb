require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:michael)
  end

  test "login with valid email/invalid password" do
    # ログイン用のパスを開く
    get login_path
    # 新しいセッションのフォームが正しく表示されたことを確認する
    assert_template 'sessions/new'
    # わざと無効なparamsハッシュを使ってセッション用パスにPOSTする
    post login_path, params: { session: { email: @user.email,
                                         password: "invalid" } }
    # ログインできてないことを確認
    assert_not is_logged_in?
    # 新しいセッションのフォームが再度表示され、フラッシュメッセージが追加されることを確認する
    assert_template 'sessions/new'
    assert_not flash.empty?
    # 別のページ（Homeページなど） にいったん移動する
    get root_path
    # 移動先のページでフラッシュメッセージが表示されていないことを確認する
    assert flash.empty?
  end
  
  test "login with valid information followed by logout" do
    get login_path
    post login_path, params: { session: { email: @user.email,
                                          password: 'password' } }
    assert is_logged_in?
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    # a[href=?]があるかどうかのテストになります。(?部分に直後の各URLが入る)
    # 各ページへのリンクがあるかどうかのテスト
    # count: 0というオプションをassert_selectに追加すると、渡したパターンに一致するリンクが０かどうかを確認するようになります。
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(@user)
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end
end
