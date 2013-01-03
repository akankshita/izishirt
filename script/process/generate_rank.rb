#!/usr/bin/env ruby
@users = User.find(:all)
for user in @users
				@rank = Rank.find_or_create_by_user_id(user.id)
				@mark = user.ordered_products.count*50+user.images.count*20+user.products.count*10
				@rank.update_attributes(:mark => @mark)
end

@ranks = Rank.find(:all, :order => 'mark DESC')	
for i in 0..@ranks.size-1
	@ranks[i].update_attributes(:rank => i+1)
end