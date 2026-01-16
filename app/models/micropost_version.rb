# frozen_string_literal: true

class MicropostVersion < ApplicationRecord
  belongs_to :micropost

  validates :content, presence: true
  validates :edited_at, presence: true

  default_scope -> { order(edited_at: :desc) }
end
