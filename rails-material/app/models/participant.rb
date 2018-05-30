class Participant < ApplicationRecord
	has_many :captures

	self.primary_key = 'userkey'

end
