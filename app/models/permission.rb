# A permission can do his sub permissions

class Permission < ActiveRecord::Base
	belongs_to :parent, :class_name => 'Permission', :foreign_key => 'parent_permission_id'

	# given the current permission, can we do a certain permission ?
	def can_do(permission_str_id)

		if str_id == permission_str_id
			return true
		end

		childs = Permission.find_all_by_parent_permission_id(id)

		childs.each do |sub_permission|

			# recursivelly scan sub permissions
			if sub_permission.can_do(permission_str_id)
				return true
			end
		end

		return false
	end

end
