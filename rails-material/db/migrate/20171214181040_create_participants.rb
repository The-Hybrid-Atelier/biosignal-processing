class CreateParticipants < ActiveRecord::Migration[5.1]
  def change
    create_table :participants do |t|
      t.integer :study_id
      t.integer :userkey

      t.timestamps
    end
  end
end
