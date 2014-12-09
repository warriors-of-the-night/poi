describe ::POI::Expo do
  Test_expo = []
  it "can get expos" do
    expos = ::POI::Expo.get_expos
    expos.each do |expo|
      expect( expo.keys ).to eq [:date, :name, :page]
    end
    Test_expo.push expos[0]
  end

  it "can get expo details" do
    expo = Test_expo[0]
    expo = ::POI::Expo.get_info( expo )
    expect( expo.keys ).to eq [:date, :name, :page, :location, :organizor, :official_site, :range, :contact]
  end
end

