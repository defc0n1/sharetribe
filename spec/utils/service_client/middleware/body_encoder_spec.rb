[
  "app/utils/service_client/middleware/middleware_base",
  "app/utils/service_client/middleware/body_encoder",
  "app/utils/transit_utils",
  "app/utils/http_utils",
].each { |file| require_relative "../../../../#{file}" }

require 'transit'
require 'active_support/json'

describe ServiceClient::Middleware::BodyEncoder do

  def expect_headers(ctx, mime_type)
    expect(ctx[:req][:headers]).to include(
                                     "Accept" => mime_type,
                                     "Content-Type" => mime_type
                                   )
  end

  let(:body_encoder) { ServiceClient::Middleware::BodyEncoder }

  describe "JSONEncoder" do

    let(:encoder) { body_encoder.new(:json) }

    it "#enter" do
      ctx = encoder.enter(req: { body: {"a" => 1}, headers: {}})

      expect(JSON.parse(ctx[:req][:body])).to eq({"a" => 1})
      expect_headers(ctx, "application/json")
    end

    it "#leave" do
      ctx = encoder.leave(res: { body: {"a" => 1}.to_json, headers: { "Content-Type" => "application/json;charset=UTF-8"} })
      expect(ctx[:res][:body]).to eq({"a" => 1})
    end
  end

  describe "TransitEncoder" do

    describe "transit+json" do

      let(:encoder) { body_encoder.new(:transit_json) }

      it "#enter" do
        ctx = encoder.enter(req: { body: {a: 1}, headers: {}})

        expect(TransitUtils.decode(ctx[:req][:body], :json)).to eq({a: 1})
        expect_headers(ctx, "application/transit+json")
      end

      it "#leave" do
        ctx = encoder.leave(res: { body: TransitUtils.encode({a: 1}, :json), headers: { "Content-Type" => "application/transit+json;charset=UTF-8"} })
        expect(ctx[:res][:body]).to eq({a: 1})
      end
    end

    describe "transit+msgpack" do

      let(:encoder) { body_encoder.new(:transit_msgpack) }

      it "#enter" do
        ctx = encoder.enter(req: { body: {a: 1}, headers: {}})

        expect(TransitUtils.decode(ctx[:req][:body], :msgpack)).to eq({a: 1})
        expect_headers(ctx, "application/transit+msgpack")
      end

      it "#leave" do
        ctx = encoder.leave(res: { body: TransitUtils.encode({a: 1}, :msgpack), headers: { "Content-Type" => "application/transit+msgpack;charset=UTF-8"} })
        expect(ctx[:res][:body]).to eq({a: 1})
      end
    end
  end

  describe "#leave" do

    let(:encoder) { body_encoder.new(:transit_msgpack) }

    it "uses the response Content-Type to define which decoder to use" do
      ctx = encoder.leave(res: { body: {a: 1}.to_json, headers: { "Content-Type" => "application/json" }})

      expect(ctx[:res][:body]).to eq("a" => 1)
    end

    it "uses the request encoder if the Content-Type header is missing" do
      ctx = encoder.leave(res: { body: TransitUtils.encode({a: 1}, :msgpack), headers: {}})

      expect(ctx[:res][:body]).to eq(a: 1)
    end
  end
end
