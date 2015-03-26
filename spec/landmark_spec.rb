require 'spec_helper'
describe POI::LandMark::MeiTuan do
  sample = POI::LandMark::MeiTuan.new
  cities = sample.city_list
	it "has 560 cities" do
    expect(cities.length).to eq 560
  end
end
