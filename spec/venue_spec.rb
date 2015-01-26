describe ::POI::Venue do

  it "can get max page num" do
    max_page_num = POI::Venue.max_page_num
  end

  it "can get venue in page" do
    venues = POI::Venue.venues_in_page( 13 )
    venues.each do |venue|
      expect(venue.keys).to eq [:id,:name,:city,:region, :address ]
    end
  end

  it "can get venue's extra info" do
    venue = { id:"123"}
    venue = POI::Venue.get_info( venue )
    expect(venue.keys).to eq [:id, :intro, :facilities ]
  end

end