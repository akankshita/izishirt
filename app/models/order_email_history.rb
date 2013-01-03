class OrderEmailHistory < ActiveRecord::Base
  belongs_to :order
  belongs_to :user
  
  def wrote_by
    begin
      return User.find(user_id).username
    rescue
      return "N/A"
    end
  end
end
