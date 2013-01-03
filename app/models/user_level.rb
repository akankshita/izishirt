class UserLevel < ActiveRecord::Base
  has_many :users, :dependent => :destroy
  has_many :contents
  has_many :newsletters
  
  # about time !
  has_many :user_level_permissions 

	def can_do(permission_str_id)

		# check out the exclusions first
		user_level_permissions.find_all_by_exclude(true).each do |u_perm|
			
			if u_perm.permission.can_do(permission_str_id)
				return false
			end
		end

		# then check out the inclusions
		# do we have a permission allowing this permission ?
		user_level_permissions.find_all_by_exclude(false).each do |u_perm|
			if u_perm.can_do(permission_str_id)
				return true
			end
		end

		return false
	end
end
