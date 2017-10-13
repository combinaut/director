RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Schema.define(version: 0) do
      create_table :schema_migrations, :force => true, :id => false do |t|
        t.string :version
      end

      create_table :active_record_mocks, :force => true do |t|
        t.string :type
      end
    end
  end
end

# Create the model
class ActiveRecordMock < ActiveRecord::Base
end
