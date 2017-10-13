def build_alias(attributes = {})
  Director::Alias.new({ source_path: '/my/source', target_path: '/my/target', handler: :redirect }.merge(attributes))
end

def create_alias(attributes = {})
  build_alias(attributes).tap do |record|
    record.save!
  end
end
