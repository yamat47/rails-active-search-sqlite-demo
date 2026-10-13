# One Aozora Bunko work, kept with the colophon Aozora asks redistributors to carry along.
class Work < ApplicationRecord
  has_many :paragraphs, -> { order(:position) }, dependent: :destroy

  validates :title, :author, :card_id, :card_url, presence: true
  validates :card_id, uniqueness: true
end
