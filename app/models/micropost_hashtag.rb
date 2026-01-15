class MicropostHashtag < ApplicationRecord
  belongs_to :micropost
  belongs_to :hashtag

  validates :micropost_id, uniqueness: { scope: :hashtag_id }
end
