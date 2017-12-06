require "rails_helper"

RSpec.describe "Media requests", type: :request do
  before do
    allow(AssetManager).to receive(:proxy_percentage_of_asset_requests_to_s3_via_nginx)
      .and_return(0)
  end

  describe "requesting an asset that doesn't exist" do
    it "responds with not found status" do
      get "/media/34/test.jpg"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "request an asset that does exist" do
    let(:asset) { FactoryBot.create(:clean_asset) }

    before do
      get "/media/#{asset.id}/asset.png", headers: {
        "HTTP_X_SENDFILE_TYPE" => "X-Accel-Redirect",
        "HTTP_X_ACCEL_MAPPING" => "#{Rails.root}/tmp/test_uploads/assets/=/raw/"
      }
    end

    it "sets the X-Accel-Redirect header" do
      expect(response).to be_success
      id = asset.id.to_s
      expect(response.headers["X-Accel-Redirect"]).to eq("/raw/#{id[2..3]}/#{id[4..5]}/#{id}/#{asset.file.identifier}")
    end

    it "sets the correct content headers" do
      expect(response.headers["Content-Type"]).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to eq('inline; filename="asset.png"')
    end

    it "sets the X-Frame-Options header to SAMEORIGIN" do
      expect(response.headers["X-Frame-Options"]).to eq('DENY')
    end
  end
end
