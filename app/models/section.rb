# A section of a guide, and the unit the search indexes hold.
#
# The same text goes into three indexes that differ only in the FTS5 tokenizer their migration
# names (config/search.rb). Writes are inline rather than through Active Job so that a seed run
# or a test sees the index as soon as the record is saved.
class Section < ApplicationRecord
  belongs_to :guide

  has_search index: :sections, default: true, async: false
  has_search index: :porter_sections, async: false
  has_search index: :trigram_sections, async: false

  validates :position, :anchor, :title, :body, presence: true

  delegate :title, to: :guide, prefix: true

  # Where the section lives on guides.rubyonrails.org.
  def url
    "#{guide.url}##{anchor}"
  end

  # "Associations › Why Associations?" for a subsection, the title alone for a top-level one.
  def breadcrumb
    [ parent_title, title ].compact.join(" › ")
  end
end
