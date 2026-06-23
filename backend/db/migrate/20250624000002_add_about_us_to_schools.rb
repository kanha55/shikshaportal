# frozen_string_literal: true

class AddAboutUsToSchools < ActiveRecord::Migration[7.2]
  def change
    add_column :schools, :about_us, :text
  end
end
