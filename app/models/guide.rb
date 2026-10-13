# One of the Rails Guides, as listed in guides/source/documents.yaml (db/corpus/README.md).
class Guide < ApplicationRecord
  has_many :sections, -> { order(:position) }, dependent: :destroy

  validates :slug, :title, :url, :source, presence: true
  validates :slug, uniqueness: true
end
