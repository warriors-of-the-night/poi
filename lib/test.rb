require 'nokogiri'
require 'open-uri'
require 'socket'
require 'active_record'

def request( url )
  """
  Sent HTTP request to baidu and grab the respond html.
  """
  # force encoding
  url = URI::encode(url)
  # here we can extract another method: separate URL
  host = URI(url).host
  uri = url[ 7 + host.length .. -1 ]

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
    html += line
    # automatically end
    break if html.include?('</HTML>') || html.include?('</html>') || html.include?('</body>')

  end
  socket.close

  return html
end

def requestX( url )
  """
  Sent HTTP request to baidu and grab the respond html.
  """
  # force encoding
  url = URI::encode(url)
  # here we can extract another method: separate URL
  host = URI(url).host
  uri = url[ 7 + host.length .. -1 ]

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
    html += line
    # automatically end
#    break if html.include?('</HTML>') || html.include?('</html>') || html.include?('</body>')
    break if html.include?'"page_type" : "list_p"'
  end
  socket.close

  return html
end


def city_in_homepage
  citys = []
  
  url ="http://www.zhuna.cn/lable/"
  html = request( url ) 
  html.force_encoding('utf-8')
  page = Nokogiri::HTML( html )
  
  page.search("div[@class='sitedh_nr']").search("dd").each do |dd|
    dd.search("a").each do |citylink|
      
      city = {}
      city[:name] = citylink.content
      city[:link] = citylink.attribute('href').value
      citys << city
      puts "#{citylink.content}"

      attraction_in_city(city)
    end
  end
  
  return citys
end

def attraction_in_city(city)
  attractions = []
  url ="http://www.zhuna.cn"

  html = request( url + city[:link].to_s ) 
  

  
  html.force_encoding('utf-8')
  page = Nokogiri::HTML( html )
  
  attraction = {}
  attractionTypes = []
  
  page.search("div[@class='sitecity_fj']").search("div[@class='sitecity_fjbt']").each do |divX|
    divX.search("a").each do |a|
      attractionTypes << a.content
    end
  end
  page.search("div[@class='sitecity_fj']").search("ul[@class='sitecity_fjlist']").each_with_index do |ulX,i|  
    ulX.search("li").search("a").each do |a|
      attraction[:name] = a.content

      attraction[:type] = attractionTypes[i]
      
      attraction[:link] = a.attribute('href').value
puts "AAA"
      attraction = coordinates(attraction)
      puts attraction[:lat]
      puts attraction[:lng]
      attractions << attraction
      puts attraction[:name].to_s + ":" + attraction[:type].to_s
      end
  end
  
  return attractions
end

def coordinates(attraction)
  url ="http://www.zhuna.cn"
  html = requestX( url + attraction[:link].to_s ) 
  coordinates =  /\"address_coord\" : \[\"(\d*\.\d*)\",\"(\d*\.\d*)\"\]/.match(html).to_s.gsub(/\"address_coord\" : \[/,'').gsub(/\]/,'').gsub(/\"/,'').split(",")
  if coordinates.length == 2
    attraction[:lat] = coordinates[0]
    attraction[:lng] = coordinates[1]
  end
  return attraction
end

city_in_homepage

#coordinates
