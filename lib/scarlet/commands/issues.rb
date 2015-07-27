require 'active_support/core_ext/string'
require 'scarlet/models/model_base'

# This will be moved into its own gem in the future called scarlet-issues or
# something along those lines.

class Scarlet
  class Comment < ModelBase
    # who commented
    field :nick_id,  type: String
    # what was commented
    field :text,     type: String

    def nick
      Nick.first(id: nick_id)
    end
  end

  class Issue < ModelBase
    field :title,      type: String
    # generated from the title
    field :uname,      type: String, default: nil
    # who started the issue
    field :nick_id,    type: String
    array :comments,   type: Comment, coerce_values: true

    def post_initialize
      super
      self.uname = title.gsub(/['"]+/, '').gsub(/[,\s]+/, '_').gsub(/_+/, '_').downcase
    end

    def new_comment(props)
      comment = Comment.new(props)
      comments << comment
      save
      comment
    end
  end
end
