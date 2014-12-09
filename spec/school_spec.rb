shared_examples "school" do |type|
  Test_url = []
  it "can get max page num" do
    max_page_num = eval("::POI::School::#{type}").max_page_num
  end

  it "can get schools in page" do
    urls = eval("::POI::School::#{type}").urls_in_page(12)
    Test_url.push urls[0]
  end

  it "can get schools extra info" do
    url = Test_url[0]
    school = eval("::POI::School::#{type}").get_info(url)
    p school
  end
end

describe ::POI::School do
  it_should_behave_like( 'school', 'Elementary' )
end
