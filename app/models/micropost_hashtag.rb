class MicropostHashtag < ApplicationRecord
  belongs_to :micropost
  belongs_to :hashtag
end
