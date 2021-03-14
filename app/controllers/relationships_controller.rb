class RelationshipsController < ApplicationController
   before_action :logged_in_user
   
  def create
    # create.jsで@userを使うのでインスタンス変数にしなきゃいけない
    @user = User.find(params[:followed_id])
    current_user.follow(@user)
    # リクエストの種類によって応答を場合分けする
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end
end
