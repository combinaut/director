require 'spec_helper'

describe Director::Middleware do

  let(:app) { MockRackApp.new }
  let(:middleware) { described_class.new(app) }
  let(:mock_request) { Rack::MockRequest.new(middleware) }
  let(:request) { Rack::Request.new(app.env) }

  shared_examples_for 'a pass-through middleware' do |request_path|
    before do
      mock_request.send(request_method, request_path)
    end

    it 'should not modify the path' do
      expect(request.path_info).to eq(request_path)
    end

    it 'should not modify the request method' do
      expect(request.request_method).to eq(request_method.to_s.upcase)
    end
  end

  shared_examples_for 'a redirect middleware' do |request_path, target_path|
    let(:response) { mock_request.send(request_method, request_path) }

    it 'should redirect to target_path' do
      expect(response).to have_attributes(location: target_path, status: 302)
    end
  end

  shared_examples_for 'a proxy middleware' do |request_path, target_path|
    before do
      mock_request.send(request_method, request_path)
    end

    it 'should set the path to the target_path' do
      expect(request.path_info).to eq(target_path)
    end

    it 'should not modify the request_method' do
      expect(request.request_method).to eq(request_method.to_s.upcase)
    end
  end

  describe 'a GET request' do
    request_path = '/pages/my_page'.freeze
    target_path = '/some/target'.freeze
    let(:request_method) { :get }

    context 'when no aliases exist' do
      before { Director::Alias.destroy_all }
      it_behaves_like 'a pass-through middleware', request_path
    end

    context 'when an alias exists but does not match' do
      before { Director::Alias.create!(source_path: 'does/not/match', target_path: target_path, handler: 'redirect') }

      it_behaves_like 'a pass-through middleware', request_path
    end

    context 'when a matching redirect alias exists' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }

      it_behaves_like 'a redirect middleware', request_path, target_path
    end

    context 'when a matching proxy alias exists' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'proxy') }

      it_behaves_like 'a proxy middleware', request_path, target_path
    end

    context 'when a matching custom alias exists' do
      class Director::Handler::CustomTest < Director::Handler::Base;
        def response(app, env)
          app.call(env)
        end
      end

      let!(:custom_alias) { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'custom_test') }

      it 'calls the custom handler' do
        expect_any_instance_of(Director::Handler::CustomTest).to receive(:response).and_call_original
        mock_request.send(request_method, request_path)
      end

      it 'raises an exception when the handler does not exist' do
        custom_alias.update_column(:handler, 'some_non_existent_handler')
        expect { mock_request.send(request_method, request_path) }.to raise_exception(Director::MissingAliasHandler)
      end
    end

    it 'matches formats without including the trailing period'

    context 'when a `format` constraint is configured' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }
      before { allow(Director::Configuration.constraints.format).to constrain }

      context 'and the request format is not in the whitelist' do
        let(:constrain) { receive(:only).and_return(:jpg) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request format is in the blacklist' do
        let(:constrain) { receive(:except).and_return(:html) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request format is in the whitelist' do
        let(:constrain) { receive(:only).and_return(:html) }
        it_behaves_like 'a redirect middleware', request_path, target_path
      end
    end

    context 'when a String `source_path` constraint is configured' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }
      before { allow(Director::Configuration.constraints.source_path).to constrain }

      context 'and the request path is not in the whitelist' do
        let(:constrain) { receive(:only).and_return(request_path + "/something") }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request path is in the blacklist' do
        let(:constrain) { receive(:except).and_return(request_path) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request path is in the whitelist' do
        let(:constrain) { receive(:only).and_return(request_path) }
        it_behaves_like 'a redirect middleware', request_path, target_path
      end
    end

    context 'when a Regexp `source_path` constraint is configured' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }
      before { allow(Director::Configuration.constraints.source_path).to constrain }

      context 'and the request path is not in the whitelist' do
        let(:constrain) { receive(:only).and_return(%r{#{request_path}/something}) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request path is in the blacklist' do
        let(:constrain) { receive(:except).and_return(%r{#{request_path}}) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request path is in the whitelist' do
        let(:constrain) { receive(:only).and_return(request_path) }
        it_behaves_like 'a redirect middleware', request_path, target_path
      end
    end
  end
end
