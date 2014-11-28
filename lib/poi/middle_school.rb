class MiddleSchool

  attr_accessor :type = 'middle'
  attr_accessor :max_page_num
  
  Type = { "elementary"=>"mainxx", "middle"=>"maincz", "high"=>"main" }

  def initialize( )
    # get max page num
    url ="http://xuexiao.eol.cn/iframe/#{Type[@type]}.php?page=1"
    html = request( url ) 
    html.force_encoding('utf-8')
    page = Nokogiri::HTML( html )
    @max_page_num = page.search("center").text[-8..-1].match('\d{2,}').to_s.to_i
    return
  end

  def request
    """
    Sent HTTP request to baidu and grab the respond html.
    """
    # force encoding
    url = URI::encode(url)
    uri = url.match(/cn.*?\z/).to_s[2..-1]
    host = url.match(/.*?eol.cn/).to_s[7..-1]

    http_request = "GET #{uri} HTTP/1.1\r\n"+
    "Content-Type: text/html; charset=utf-8\r\n"+
    "Host:#{host}\r\n"+
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"+
    "Connection:keep-alive\r\n"+
    "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0\r\n\r\n"
    socket = TCPSocket.open( host, 80)

    socket.puts( http_request)

    html = ""
    while line = socket.gets
      p line
      html += line
      # automatically end
      break if html.include?('</HTML>') || html.include?('</html>')
    end
    socket.close

    return html
  end

  def urls_in_page( page_i , type = @type )
    url ="http://xuexiao.eol.cn/iframe/#{Type[@type]}.php?page=#{page_i}"
    html = request( url ) 
    page = Nokogiri::HTML( html )

    urls = []
    ( page.search('h1') + page.search('h5') ).each do |heading|
      urls << heading.search('a').attribute('href').value
    end

    return urls
  end

  def get_info( url )
    html = request( url )
    page = Nokogiri::HTML( html )

    school = {}
    school[:name] = page.search('title').text.split('-')[0]

    table = page.search("table[@class='line_22']")
    table.search('td').each do |line0|
      line = line0.text
      if line[0,2] == "校址"
        school[:address] = line[3..-1]
      elsif line[0,2] == "地区"
        school[:region] = line[3..-1]
      elsif line[0,2] == "网址"
        school[:website] = line0.search('a').first.attribute('href').value
      elsif line[0,2] == "电话"
        school[:phone] = line[3..-1]
      end
    end

    school[:type] = @type
    return school
  end

end