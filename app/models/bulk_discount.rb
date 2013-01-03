class BulkDiscount < ActiveRecord::Base
  belongs_to :model
  validates_numericality_of :start, :percentage
  validates_presence_of :start, :percentage

  def self.defaults
    BulkDiscount.find_all_by_is_default(true, :order => :start)
  end

  def self.default_discount_string
    BulkDiscount.defaults.map{|bd|"#{bd.start}_#{bd.percentage}"}.join("|")
  end

  def self.discount_string(model_id)
  #
  if model_id.to_i > 0
	  @modelinfos = Model.find(model_id)
	   if @modelinfos.nodiscount== true
			return nil
		end
	  
  end
  #
    if ApplicationSetting.use_per_model_discount? && 
       model_id && BulkDiscount.exists?(:model_id => model_id)
      return BulkDiscount.find_all_by_model_id(model_id, 
                            :order => :start).map{|bd|"#{bd.start}_#{bd.percentage}"}.join("|")
    else
      return BulkDiscount.find_all_by_is_default(true,
                            :order => :start).map{|bd|"#{bd.start}_#{bd.percentage}"}.join("|")
    end
  end
  def self.percentage_by_qty(qty, model_id=nil)
  #
  if model_id.to_i > 0
	  @modelinfos=Model.find(model_id.to_i)
	  if @modelinfos.nodiscount== true
			return 0
		end
	  
  end
  #
    begin
      
      if model_id && BulkDiscount.exists?(:model_id => model_id) 
        @bulk_discount = BulkDiscount.find(:last, 
                                     :conditions => ["model_id = ? and start <= ?", model_id, qty],
                                     :order => :start)
      else
        @bulk_discount = BulkDiscount.find(:last, 
                                     :conditions => ["is_default = ? and start <= ?", true, qty],
                                     :order => :start)
      end

      return @bulk_discount ? @bulk_discount.percentage / 100.0 : 0.0
    rescue
      return 0
    end
  end

  def self.next_discount_by_qty(qty, model_id=nil)
  #
  if model_id.to_i > 0
	  @modelinfos=Model.find(model_id.to_i)
	  if @modelinfos.nodiscount== true
			return nil
		end
	 
  end
  #
    begin
      
      if model_id && BulkDiscount.exists?(:model_id => model_id) 
        @bulk_discount = BulkDiscount.find(:first,
                                     :conditions => ["model_id = ? and start > ?", model_id, qty],
                                     :order => :start)
      else
        @bulk_discount = BulkDiscount.find(:first, 
                                     :conditions => ["is_default = ? and start > ?", true, qty],
                                     :order => :start)
      end

      return @bulk_discount
    rescue
      return nil
    end
  end
end
