require 'spec_helper'

describe Director::Middleware do
  let(:app) { MockRackApp.new }
  let(:middleware) { described_class.new(app) }
  let(:mock_request) { Rack::MockRequest.new(middleware) }
  let(:request) { Rack::Request.new(app.env) }

  describe '::original_request_url' do
    it 'returns the original request url' do
      original_url = 'http://www.test.com/some/path'
      mock_request.get original_url
      expect(Director::Middleware.original_request_url(request)).to eq(original_url)
    end
  end

  describe '::handled_request?' do
    it 'returns true if the request is a GET' do
      mock_request.get 'http://www.test.com/some/path'
      expect(Director::Middleware.handled_request?(request)).to be_truthy
    end

    it 'returns true if the request is a HEAD' do
      mock_request.head 'http://www.test.com/some/path'
      expect(Director::Middleware.handled_request?(request)).to be_truthy
    end

    it 'returns false if the request is a POST' do
      mock_request.post 'http://www.test.com/some/path'
      expect(Director::Middleware.handled_request?(request)).to be_falsey
    end

    it 'returns false if the request is a PATCH' do
      mock_request.patch 'http://www.test.com/some/path'
      expect(Director::Middleware.handled_request?(request)).to be_falsey
    end

    it 'returns false if the request is a DELETE' do
      mock_request.delete 'http://www.test.com/some/path'
      expect(Director::Middleware.handled_request?(request)).to be_falsey
    end

    context 'when the default request constraint is reconfigured' do
      before { allow(Director::Configuration.constraints.request).to receive(:only).and_return constraint }
      let(:constraint) { ->(request) { request.post? } }

      it 'returns true if the constraint allows the request' do
        mock_request.post 'http://www.test.com/some/path'
        expect(Director::Middleware.handled_request?(request)).to be_truthy
      end

      it 'returns false if the constraint does not allow the request' do
        mock_request.get 'http://www.test.com/some/path'
        expect(Director::Middleware.handled_request?(request)).to be_falsey
      end
    end
  end

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

    it 'responds with a redirect' do
      expect(response).to have_attributes(status: 302)
    end

    it 'includes the target_path in the redirect location' do
      expect(response).to have_attributes(location: include(URI(target_path).path), status: 302)
    end

    it 'includes the target query in the redirect location' do
      expect(response).to have_attributes(location: include(URI(target_path).query.to_s))
    end

    it 'includes the request query in the redirect location' do
      expect(response).to have_attributes(location: include(URI(request_path).query.to_s))
    end
  end

  shared_examples_for 'a proxy middleware' do |request_path, target_path|
    before do
      mock_request.send(request_method, request_path)
    end

    it 'should set the path to the target_path' do
      expect(request.path_info).to eq(URI(target_path).path)
    end

    it 'should not modify the request_method' do
      expect(request.request_method).to eq(request_method.to_s.upcase)
    end

    it 'proxies the incoming request query' do
      expect(request.query_string).to include(URI(request_path).query.to_s)
    end

    it 'retains the target path query' do
      expect(request.query_string).to include(URI(target_path).query.to_s)
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
      before { Director::Alias.create!(source_path: '/does/not/match', target_path: target_path, handler: 'redirect') }

      it_behaves_like 'a pass-through middleware', request_path
    end

    context 'when a matching redirect alias exists' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }

      it_behaves_like 'a redirect middleware', request_path, target_path

      context 'when a query is present in the request and target urls' do
        request_path_with_query = request_path + "?request_param=1"
        target_path_with_query = target_path + "?target_param=2"
        before { Director::Alias.where(source_path: request_path).update_all(target_path: target_path_with_query) }

        it_behaves_like 'a redirect middleware', request_path_with_query, target_path_with_query
      end
    end

    context 'when a matching proxy alias exists' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'proxy') }

      it_behaves_like 'a proxy middleware', request_path, target_path

      context 'when a query is present in the request and target urls' do
        request_path_with_query = request_path + "?request_param=1"
        target_path_with_query = target_path + "?target_param=2"
        before { Director::Alias.where(source_path: request_path).update_all(target_path: target_path_with_query) }

        it_behaves_like 'a proxy middleware', request_path_with_query, target_path_with_query
      end
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

    context 'when a `lookup_scope` constraint is configured' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }
      before { allow(Director::Configuration.constraints).to receive(:lookup_scope).and_return constraint }
      let(:constraint) { proc { -> { where('1=0') } } }

      it 'passes the request object to the scope' do
        expect(constraint).to receive(:call).with(instance_of(Rack::Request)).and_call_original
        mock_request.send(request_method, request_path)
      end

      context 'and the constraint is not met' do
        let(:constraint) { proc { -> { where('1=0') } } }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the constraint is met' do
        let(:constraint) { proc { -> { where('1=1') } } }
        it_behaves_like 'a redirect middleware', request_path, target_path
      end
    end

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

    context 'when a `request` constraint is configured' do
      before { Director::Alias.create!(source_path: request_path, target_path: target_path, handler: 'redirect') }
      before { allow(Director::Configuration.constraints.request).to constrain }

      context 'and the request is not in the whitelist' do
        let(:constrain) { receive(:only).and_return(->(request) { false }) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request is in the blacklist' do
        let(:constrain) { receive(:except).and_return(->(request) { true }) }
        it_behaves_like 'a pass-through middleware', request_path
      end

      context 'and the request is in the whitelist' do
        let(:constrain) { receive(:only).and_return(->(request) { true }) }
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
