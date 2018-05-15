class Capture < ApplicationRecord
	# mount_uploader :file, CloudinaryUploader
	mount_uploader :file, SimpleAssetUploader
	belongs_to :participant

end
