require 'spec_helper'

describe Director::ModelExtensions do
  class ModelExtensionsRecordMock < ActiveRecordMock
    has_aliased_paths canonical_path: :canonical_path

    def canonical_path
      '/canonical/path/from/mock'
    end
  end

  let(:alias_entry) { create_alias }

  describe '#incoming_aliases' do
    subject { ModelExtensionsRecordMock.create }

    it 'returns aliases where the target is self' do
      alias_entry = create_alias(target: subject)
      expect(subject.incoming_aliases).to include(alias_entry)
    end

    it 'does not return aliases where the target is not self' do
      alias_entry = create_alias
      expect(subject.incoming_aliases).not_to include(alias_entry)
    end
  end

  describe '#outgoing_alias' do
    subject { ModelExtensionsRecordMock.create }

    it 'returns the alias where the source is self' do
      alias_entry = create_alias(source: subject)
      expect(subject.outgoing_alias).to eq(alias_entry)
    end

    it 'does not return aliases where the source is not self' do
      alias_entry = create_alias
      expect(subject.outgoing_alias).not_to eq(alias_entry)
    end
  end

  describe '#save' do
    subject { ModelExtensionsRecordMock.new }

    it 'updates the alias source path when assigned as the source record' do
      alias_entry.update_attribute(:source, subject)
      allow(subject).to receive(:canonical_path).and_return('/a/new/path')
      expect { subject.save }.to change { alias_entry.reload.source_path }.to subject.canonical_path
    end

    it 'updates the alias target path when assigned as the target record' do
      alias_entry.update_attribute(:target, subject)
      allow(subject).to receive(:canonical_path).and_return('/a/new/path')
      expect { subject.save }.to change { alias_entry.reload.target_path }.to subject.canonical_path
    end

    it 'ignores blank nested attributes for outgoing_alias'
  end

  describe '#destroy' do
    subject { ModelExtensionsRecordMock.create }

    it 'deletes the outgoing alias' do
      subject.outgoing_alias = create_alias
      expect { subject.destroy }.to change { Director::Alias.where(source: subject).count }.to(0)
    end

    it 'does not destroy aliases where it is not the target' do
      create_alias
      expect { subject.destroy }.not_to change { Director::Alias.count }
    end

    it 'deletes the incoming_aliases alias' do
      subject.incoming_aliases << create_alias
      expect { subject.destroy }.to change { Director::Alias.where(target: subject).count }.to(0)
    end

    it 'does not destroy aliases where it is not the target' do
      create_alias
      expect { subject.destroy }.not_to change { Director::Alias.count }
    end
  end
end
