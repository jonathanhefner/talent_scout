class CreatePosts < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :title
      t.integer :category
      t.boolean :published

      t.timestamps
    end
  end
end
