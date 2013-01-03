class ModelZone < ActiveRecord::Base
  belongs_to :model
  
  validates_numericality_of :max_images, :max_lines, :bottom_right_x, :bottom_right_y, :top_left_x, :top_left_y

  def style(ruler_size=0)
    "position:absolute;border:1px solid black;top:#{top_left_y+ruler_size}px;left:#{top_left_x+ruler_size}px;width:#{bottom_right_x - top_left_x}px;height:#{bottom_right_y-top_left_y}px;z-index:99;"
  end
end
