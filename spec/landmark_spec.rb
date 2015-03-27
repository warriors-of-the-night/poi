require 'spec_helper'
describe POI::LandMark::MeiTuan do
  sample = POI::LandMark::MeiTuan.new
  cities = sample.city_list

	it "has 560 cities" do
    expect(cities.length).to eq 560
  end

  it "second last city is 华容" do
  	expect(cities[-2][:city_cn]).to eq '华容'
  end

  it "has keys :city_cn,:city_id of each city" do
    cities.each do |city|
      city.should have_key(:city_cn)
      city.should have_key(:city_id)
    end
  end 

  landmarks = sample.landmarks(cities[0])
  it "has 383 landmarks in beijing" do
    expect(landmarks.length).to eq 383
  end

end
