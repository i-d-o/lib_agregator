class Book < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
  include SeoName

  has_and_belongs_to_many :authors
  has_and_belongs_to_many :tags
  belongs_to :genre

  validates :title, presence: true

  mapping do
    indexes :title
    indexes :description
  end

  def self.search_by_title(word, limit = 100, offset = 0)
    search = Tire::Search::Search.new('books', load: true)
    search.query { string("title:#{word}") }
    # p '@'*88
    # p search.results
    # p '@'*88
    pointers = search.results
    pointers = pointers.drop(offset) if offset > 0
    pointers = pointers.first(limit)

    ActiveRecord::Associations::Preloader.new.preload(pointers, :authors)

    pointers.reverse # .uniq { |i| [i.title, i.domain, i.description] } # remove old duplicates from yakaboo
  end

  def self.extended_search(params, _limit = 100, _offset = 0)
    result = []

    search = Tire::Search::Search.new('books')
    search.query { string("title:#{params[:word]}") }

    ids = search.results.pluck(:id)

    if ids.present?
      query = where(id: ids)
      query = query.where(genre_id: params[:genre]) if params[:genre]

      if params[:format]
        formats = []
        params[:format].each do |frmt|
          formats << "`#{frmt}` IS NOT NULL"
        end
        frmt_condition = formats.join(' OR ')
        query = query.where(frmt_condition)
      end

      cols = attribute_names - %w(description source domain genre_id)
      result = query.select(cols).includes(:authors).all

      # result = query.includes(:authors)
      #         .limit(limit).offset(offset)
      #         .all.reverse.uniq { |i| [i.title, i.domain, i.description] }
    end

    result
  end

  def author_title
    authors.present? ? authors[0].title : ''
  end
end
