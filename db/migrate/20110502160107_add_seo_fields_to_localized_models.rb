class AddSeoFieldsToLocalizedModels < ActiveRecord::Migration
  def self.up
    add_column :localized_models, :create_meta_title, :string, :default=>""
    add_column :localized_models, :create_meta_description, :text, :default=>""
    add_column :localized_models, :create_meta_keywords, :string, :default=>""
    add_column :localized_models, :create_h1, :string, :default=>""
    add_column :localized_models, :create_desc, :text, :default=>""
  end

  def self.down
    remove_column :localized_models, :create_meta_title
    remove_column :localized_models, :create_meta_description
    remove_column :localized_models, :create_meta_keywords
    remove_column :localized_models, :create_h1
    remove_column :localized_models, :create_desc
  end
end
