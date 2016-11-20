# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'parallel'
require 'csv'

class App
  attr_reader :id, :name, :position, :rate, :star5, :star4, :star3, :star2, :star1, :published, :numDownloads, :softwareVersion

  def initialize(id, position)
    @id=id
    @position = position
  end

  def fetch
    @url = "https://play.google.com/store/apps/details?id=#{id}"
    app_page = Nokogiri::HTML(open(@url), nil, Encoding::UTF_8.to_s)


    @name = app_page.css('.id-app-title').text;
    @rate = app_page.css('.rating-box .score').text
    @star5 = app_page.css('.rating-box .rating-bar-container.five .bar-number').text
    @star4 = app_page.css('.rating-box .rating-bar-container.four .bar-number').text
    @star3 = app_page.css('.rating-box .rating-bar-container.three .bar-number').text
    @star2 = app_page.css('.rating-box .rating-bar-container.two .bar-number').text
    @star1 = app_page.css('.rating-box .rating-bar-container.one .bar-number').text

    @published = app_page.css('.details-section-contents .content').select{|x| x["itemprop"] == "datePublished"}[0].text
    @numDownloads = app_page.css('.details-section-contents .content').select{|x| x["itemprop"] == "numDownloads"}[0].text
    @softwareVersion = app_page.css('.details-section-contents .content').select{|x| x["itemprop"] == "softwareVersion"}[0].text if app_page.css('.details-section-contents .content').select{|x| x["itemprop"] == "softwareVersion"}[0]
  end
end

page = Nokogiri::HTML(open("https://play.google.com/store/apps/category/FINANCE/collection/topselling_free"), nil, Encoding::UTF_8.to_s)

cards = page.css('div.card')
time = Time.new
today = time.strftime("%Y-%m-%d")

Parallel.each_with_index(cards, in_threads: 4) do |card, index|
  id=card['data-docid']
  filename = "#{id}.csv"
  fileExists = File.file?(filename)

  unless fileExists
    CSV.open(filename, "a+") do |csv|
      csv << ["Dátum", "Pozíció", "*", "5*", "4*", "3*", "2*", "1*", "Élesítve", "Letöltések", "Ver"]
    end
  end
  noToday = File.readlines(filename).grep(/#{today}/).size == 0
  if noToday
    app = App.new(id, index);
    app.fetch();
    CSV.open(filename, "a+") do |csv|
      csv << [time.strftime("%Y-%m-%d"), app.position, app.rate, app.star5, app.star4, app.star3, app.star2, app.star1, app.published, app.numDownloads, app.softwareVersion]
    end
  end
end
