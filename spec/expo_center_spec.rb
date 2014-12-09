describe ::POI::ExpoCenter do
  it "can get expo ids" do
    ids = ::POI::ExpoCenter.get_center_ids
  end

  it "can get expo details" do
    test_id = 466
    expo_center = ::POI::ExpoCenter.get_info( test_id )
    expect( expo_center.keys ).to eq [:id, :original_url, :name, :city, :website, :address, :intro, :contact]
  end
end

