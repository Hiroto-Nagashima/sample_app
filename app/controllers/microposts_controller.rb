class MicropostsController < ApplicationController
   before_action :logged_in_user, only: [:create, :destroy]
  # current_userの投稿があるかチェック。
   before_action :correct_user,   only: :destroy

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.save
      flash[:success] = "Micropost created!"
      redirect_to root_url
    else
      @feed_items = current_user.feed.paginate(page: params[:page])
      render 'static_pages/home'
    end
  end


  def destroy
    @micropost.destroy
    flash[:success] = "Micropost deleted"
    # request.referrer 一つ前のURLを返します（今回の場合、Homeページになります）
    # 元に戻すURLが見つからなかった場合でもrootに戻る
    # redirect_back(fallback_location: root_url)と同じ
    redirect_to request.referrer || root_url
  end
  
  private

    def micropost_params
      params.require(:micropost).permit(:content)
    end
    # あるユーザーが他のユーザーのマイクロポストを削除しようとすると、自動的に失敗するようになります。
    # 現在のユーザーが削除対象のマイクロポストを保有しているかどうかを確認します。
    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end
end
