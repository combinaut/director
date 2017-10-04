ActiveRecord::Schema.define do
  create_table :aliases, force: true do |t|
    t.text :source_path, limit: 2.kilobytes # Max IE url length
    t.text :target_path, limit: 2.kilobytes
    t.references :source, polymorphic: true, index: true
    t.references :target, polymorphic: true, index: true
    t.string :handler
    t.references :creator, index: true
    t.timestamps null: false
  end

  add_index :aliases, :source_path, length: 3.kilobytes / 3
  add_index :aliases, :handler
end
