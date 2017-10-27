#!/usr/bin/env ruby

require 'net/http'
require 'feedjira'
require 'base64'
require 'nokogiri'
require 'open-uri'
require 'json'

# Misc
$today_date = Date.today.strftime("%Y-%m-%d")

# Feedjira
Feedjira.configure do |config|
    config.parsers = [
      Feedjira::Parser::Atom
    ]
  end
# Vodostaj
$vodostaj
vodostaj_url = "http://www.hidmet.gov.rs/latin/prognoza/prognoza_voda.xml"
reka = "Reka: TISA - Hidrološka stanica: TITEL"

# Kurs
$kurs
kurs_url = "http://www.nbs.rs/kursnaListaModul/srednjiKurs.faces"
valuta = 300 # Drahma

#$kurs
$belex
belex_simbol = 'JESV'
belex_date = Date.today.strftime("%d.%m.")
belex_url = "http://www.belex.rs/json/hartija.php?s=#{belex_simbol}&p=m&t=line"


# Vodostaj feed
feed = Feedjira::Feed.fetch_and_parse vodostaj_url
feed.entries.each do |entry|
    if entry.title == reka
        $vodostaj = /\d+?(?= cm;)/.match(entry.summary)
    end
end

# Belex parse

belex_uri = URI(belex_url)
belex_response = Net::HTTP.get(belex_uri)
belex_obj = JSON.parse(belex_response)
belex_obj["dataProvider"].each do |bx|
    if bx["vreme"] == belex_date
        $belex = bx["bv"].to_f
    end
end

# Kurs parse
kurs_page = Nokogiri::HTML(open(kurs_url))   
kurs_table = kurs_page.css("table[@id='index:srednjiKursLista']")
kurs_table.search('tr').each do |div|
    div_row = div.search('td').first.to_s
    code = /\d+/.match(div_row).to_s

    if code.to_i == valuta
        $kurs = div.search('td').last.text.to_f
   end
end


puts "Merna stanica: #{reka}"
puts "Trenutni vodostaj: #{$vodostaj}"
vodostaj_encoded = Base64.encode64($vodostaj.to_s)
puts "Base64 enkodiran vodostaj: #{vodostaj_encoded}"
puts "Kurs Dinara prema Grckoj Drahmi na dan #{$today_date}: #{$kurs}"
kurs_encoded = Base64.encode64($kurs.to_s)
puts "Base64 enkodiran kurs: #{kurs_encoded}"
puts "Cena Hartije od Vrednosti preduzeca JEDINSTVO SEVOJNO: #{$belex}"
belex_encoded  = Base64.encode64($belex.to_s)
puts "Base64 enkodirana cena hartije od vrednosti: #{belex_encoded}"
enc_time = vodostaj_encoded.sum + kurs_encoded.sum + belex_encoded.sum
puts "Konvertovano u sekunde: #{enc_time}"


t = Time.new(0)
enc_time.downto(0) do |i|
    puts (t + i).strftime('%H:%M:%S')
    sleep 1
end
puts "Please switch communication channel now"
system(%Q{say -v Veena "Please switch communication channel. Now!"})
