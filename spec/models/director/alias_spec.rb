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

  describe '::resolve' do
    let(:alias1) { build_alias(source_path: '/path1', target_path: '/path2') }
    let(:alias2) { build_alias(source_path: '/path2', target_path: '/path3') }
    let(:alias3) { build_alias(source_path: '/path3', target_path: '/path4') }

    it 'follows chains of non-redirect aliases where the target_path of one matches the source_path of the next' do
      [alias1, alias2, alias3].each {|alias_entry| alias_entry.update_attribute(:handler, :proxy) }
      expect(described_class.resolve('/path1')).to eq(alias3)
    end

    it 'returns a redirect alias immediately when it is not the last alias in a chain' do
      [alias1, alias3].each {|alias_entry| alias_entry.update_attribute(:handler, :proxy) }
      alias2.update_attribute(:handler, :redirect)

      expect(described_class.resolve('/path1')).to eq(alias2)
    end

    it 'returns the alias preceding a passthrough' do
      [alias1, alias2].each {|alias_entry| alias_entry.update_attribute(:handler, :proxy) }
      alias3.update_attribute(:handler, :passthrough)

      expect(described_class.resolve('/path1')).to eq(alias2)
    end

    it 'ignores trailing slashes' do
      alias1.update_attribute(:handler, :redirect)
      expect(described_class.resolve(alias1.source_path + '/')).to eq(alias1)
    end

    it 'does not ignore trailing slash on a root path' do
      alias1.update_attributes!(source_path: ' / ', handler: :redirect)
      expect(described_class.resolve('   /    ')).to eq(alias1)
    end

    it 'is case insensitive' do
      alias1.update_attributes(handler: :redirect, source_path: '/camelCasePath')
      expect(described_class.resolve(alias1.source_path.upcase)).to eq(alias1)
    end

    it 'raises an exception if an alias chain loop is detected on a proxy alias' do
      [alias1, alias2, alias3].each {|alias_entry| alias_entry.update_attribute(:handler, :proxy) }
      alias3.update_attribute(:target_path, alias1.source_path)
      expect { described_class.resolve(alias1.source_path) }.to raise_exception(Director::AliasChainLoop)
    end

    it 'raises an exception if an alias chain loop is detected on a redirect alias' do
      [alias1, alias2].each {|alias_entry| alias_entry.update_attribute(:handler, :proxy) }
      alias3.update_attributes(handler: :redirect, target_path: alias1.source_path)
      expect { described_class.resolve(alias1.source_path) }.to raise_exception(Director::AliasChainLoop)
    end
  end

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

    it 'sets the target_path if a target is already present, even if a target_path is set to something else' do
      subject.update_attribute(:target, record)
      subject.attributes = { target_path: '/asdf' }
      expect { subject.save }.to change { subject.target_path }.to record.canonical_path
    end

    it 'sets the source_path if a source is already present, even if a source_path is set to something else' do
      subject.update_attribute(:source, record)
      subject.attributes = { source_path: '/asdf' }
      expect { subject.save }.to change { subject.source_path }.to record.canonical_path
    end

    it 'removes leading and trailing whitespace from source_path' do
      subject.attributes = { source_path: '/asdf    ' }
      expect { subject.save }.to change { subject.source_path }.to '/asdf'
    end

    it 'removes leading and trailing whitespace from target_path' do
      subject.attributes = { target_path: '/asdf    ' }
      expect { subject.save }.to change { subject.target_path }.to '/asdf'
    end

    it 'raises an exception if redirection aliases would result in a loop'
  end

  describe '#valid?' do
    it 'returns true if the source_path matches the `only` constraint' do
      pending 'Need to figure out how to set the configuration before the validations are created'
      allow(Director::Configuration.constraints.source_path).to receive(:only).and_return(%r{/this/is/a/test})
      expect { subject.source_path = '/this/is/a/test' }.to change { subject.valid? }.to true
    end

    it 'returns false if the handler does not exist' do
      expect { subject.handler = 'FakeHandler' }.to change { subject.valid? }.to false
    end

    it 'returns false if source_path includes interior whitespace' do
      expect { subject.source_path = '/this is/a/test' }.to change { subject.valid? }.to false
    end

    it 'returns false if target_path includes interior whitespace' do
      expect { subject.target_path = '/this is/a/test' }.to change { subject.valid? }.to false
    end

    it 'returns false if source_path is relative and does not start with a slash' do
      expect { subject.source_path = 'this/is/a/test' }.to change { subject.valid? }.to false
    end

    it 'returns false if target_path is relative and does not start with a slash' do
      expect { subject.target_path = 'this/is/a/test' }.to change { subject.valid? }.to false
    end

    it 'returns returns true if target_path is absolute and does not start with a slash' do
      expect { subject.target_path = 'http://www.this.com/is/a/test' }.not_to change { subject.valid? }.from true
    end

    it 'returns false if the `source_path` and the `target_path` are equal' do
      expect { subject.target_path = subject.source_path }.to change { subject.valid? }.to false
    end
  end
end
