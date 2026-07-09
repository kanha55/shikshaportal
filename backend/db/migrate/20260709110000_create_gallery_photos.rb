class CreateGalleryPhotos < ActiveRecord::Migration[7.2]
  def change
    create_table :gallery_photos do |t|
      t.references :school, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :caption
      t.timestamps
    end

    add_index :gallery_photos, %i[school_id position], unique: true
  end
end
