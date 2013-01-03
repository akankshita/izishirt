
class PreviewGeneratorDesign
  attr_reader :design_path, :v_reflection, :h_reflection, :zoom, :rotation, :x, :y
  
  def initialize (design_path, v_reflection, h_reflection, zoom, rotation, x, y)
    @design_path = design_path
    @v_reflection = v_reflection
    @h_reflection = h_reflection
    @zoom = zoom
    @rotation = rotation
    @x = x
    @y = y
  end
end