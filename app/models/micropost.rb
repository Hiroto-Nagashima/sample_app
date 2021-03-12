class Micropost < ApplicationRecord
  belongs_to :user
  # データベースから要素を取得したときの、デフォルトの順序を指定するメソッド
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
end
