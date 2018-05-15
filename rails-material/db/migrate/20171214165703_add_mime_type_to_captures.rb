class AddMimeTypeToCaptures < ActiveRecord::Migration[5.1]
  def change
  	add_column :captures, :mime_type, :string, :default => "mp4"
  end
end
