class AddNotesToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :comments, :text
  end
end
