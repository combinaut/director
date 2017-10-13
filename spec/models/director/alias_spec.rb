require 'spec_helper'

describe Director::Alias do
  subject { build_alias }

  class AliasRecordMock < ActiveRecordMock
    has_aliased_paths canonical_path: :canonical_path

    def canonical_path
      '/canonical/path/from/mock'
    end
  end

  let(:record) { AliasRecordMock.create! }

  describe '#save' do
    it 'sets the source_path when a source record is provided' do
      subject.source = record
      expect { subject.save }.to change { subject.source_path }.to record.canonical_path
    end

    it 'does not modify the source_path if no source record is provided' do
      subject.source = nil
      expect { subject.save }.not_to change { subject.source_path }
    end

    it 'sets the target_path when a target record is provided' do
      subject.target = record
      expect { subject.save }.to change { subject.target_path }.to record.canonical_path
    end

    it 'does not modify the target_path if no target record is provided' do
      subject.target = nil
      expect { subject.save }.not_to change { subject.target_path }
    end

    it 'does raises an exception if redirection aliases would result in a loop'
  end
end
