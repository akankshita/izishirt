# -*- coding: utf-8 -*-
class Province < ActiveRecord::Base
	belongs_to :country
	has_many :addresses
	has_many :cities

  def name_url
    name.gsub(/[ÁÀÂÄáàâä]+/,'a').gsub(/[ÉÈÊËèéêë]+/,'e').gsub(/[ÎÍÌÏîíìï]+/,'i').gsub(/\s/,'-').gsub(/[']/,'-').gsub('.','').downcase
  end
  
end
