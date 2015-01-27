require 'spec_helper'
describe ::POI::Dianping do
  selector = "//h2[text()='商区']/.."
  it "can get city number 403" do
   expect(::POI::Dianping.cities.size).to eq 403
  end

  it "can get business in guangzhou" do
    expect(::POI::Dianping.centers('4', 'center', selector)[0].keys).to eq [:name, :type, :center_id, :city_id, :city_name]

  end

end