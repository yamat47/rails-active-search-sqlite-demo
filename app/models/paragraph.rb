# A paragraph of a work, and the unit the search indexes hold.
#
# The same text goes into three indexes that differ only in how FTS5 tokenizes it (config/search.rb).
# Writes are inline rather than through Active Job so that a seed run or a test sees the index as
# soon as the record is saved.
class Paragraph < ApplicationRecord
  belongs_to :work

  has_search index: :paragraphs, default: true, async: false
  has_search index: :trigram_paragraphs, async: false
  has_search index: :segmented_paragraphs, async: false, serializer: :to_segmented_document

  validates :position, :body, presence: true

  delegate :author, to: :work
  delegate :title, to: :work, prefix: :work

  # unicode61 sees a run of kanji and kana as one token, so the text is split into words first and
  # the query goes through the same split (see SearchStrategy).
  def to_segmented_document
    { body: TinySegmenter.wakati(body), author: author, work_title: work_title, work_id: work_id }
  end
end
