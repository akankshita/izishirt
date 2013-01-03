class UserLevelPermission < ActiveRecord::Base
	belongs_to :user_level
	belongs_to :permission

	def can_do(permission_str_id)

		return permission.can_do(permission_str_id)
	end
end
