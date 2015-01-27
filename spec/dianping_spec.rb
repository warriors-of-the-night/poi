require './spec_helper'
describe ::POI::Dianping do
  it "can get city number 403" do
   expect(::POI::Dianping.cities.size).to eq 403
  end

  it "can get business centers in guangzhou" do
    expect(::POI::Dianping.pois('4')[0].keys).to eq [:name, :cata, :center_id, :city_id, :city_name]

  end

end