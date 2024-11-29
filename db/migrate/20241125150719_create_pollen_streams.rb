# frozen_string_literal: true

class CreatePollenStreams < ActiveRecord::Migration[7.2]
  def change
    create_table :pollen_streams, id: false, primary_key: :id do |t|
      t.string :id, primary_key: true
      t.string :owner_id, index: true
      t.text :payload
      t.integer :status, null: false, default: 0
      t.integer :timeout, null: false, default: 120
      t.timestamps
    end
  end
end
