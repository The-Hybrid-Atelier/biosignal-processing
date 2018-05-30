class CreateCaptures < ActiveRecord::Migration[5.1]
  def change
    create_table :captures do |t|
      t.string :file
      t.string :file_cache
      t.string :tags

      t.timestamps
    end
  end
end
