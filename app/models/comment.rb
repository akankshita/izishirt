class Comment < ActiveRecord::Base
belongs_to :order
belongs_to :user
belongs_to :comment_type
# fields:
#id
#user_id
#order_id
#comment
#date_time
  def username
    begin
      return user.username
    rescue
      return "N/A"
    end
  end
end
