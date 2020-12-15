#Objective: search google for websites related to a set of keywords that allow guest posts on their site
# return cleaned results to a new xls file (remove duplicate root domains)

require 'nokogiri'
require 'open-uri'
require 'spreadsheet'

class DomainScraper
  attr_reader :domain_list
def initialize
  @domain_list = Hash.new #key = domain, val = DomainResult object
end

def find_root_domain(url)
  url.delete_prefix!("http://")
  url.delete_prefix!("https://")
  url.delete_prefix!("www.")
  url = url.partition("/")[0]
end

def format_query(phrase)
  phrase.split(" ").join("+")
end

def get_search_results(query, num_results, submission_keyword="write for us")
  search_results = []
  query_words = format_query(query) + "+" + format_query(submission_keyword)
  doc = Nokogiri::HTML(URI.open("https://google.com/search?q=#{query_words}&num=#{num_results}"))
  doc.css('h3').each do |item|
      search_results << item
    end
  search_results.each_index do |i|
    doc.css('a').each do |link|
      if link.content.include? search_results[i]
        link_title = search_results[i].content
        article_link = link['href'].delete_prefix!("/url?q=").partition('/&sa')[0]
        domain = find_root_domain(article_link)
        @domain_list[domain] = DomainResult.new(domain, link_title, article_link) unless @domain_list.has_key?(domain)
      end
    end
  end
  return @domain_list
end

def get_many_search_results(query_list, num_results, submission_keyword_list) #taking array, num, array; runs get_search_results
  query_list.each do |query|
    submission_keyword_list.each do |variant|
      get_search_results(query, num_results, variant)
    end
  end
end

def get_related_searches(query) #not working
  doc = Nokogiri::HTML(URI.open("https://google.com/search?q=#{format_query(query)}"))
  related_searches = doc.css(".div.card-section") #'nVcaUb'
  #puts related_searches.is_nil?
  puts related_searches.length
  puts related_searches.is_a? Array
  #puts related_searches#.each {|item| puts item}
end

def write_results_to_file(domain_list)
f = File.open("test_file.rb", "w")
f.write "Some text..."
f.close
f = File.open("test_file.rb", "a")
domain_list.each do |key,value|
  f.write "\n" + "domain: #{key}"
  f.write "\n" + "title: #{value.link_title}"
  f.write "\n" + "link: #{value.article_link}"
  f.write "\n"
end
f.write "\n" + "hello again"
f.close
end

def write_results_to_xls(new_xls_filename, domain_list, worksheet_name="Worksheet 1")
  file = Spreadsheet::Workbook.new
  file.create_worksheet :name => "#{worksheet_name}"
  file.worksheet(0).insert_row(0, ["Domain", "Link Title", "Link"])
  row = 1
  domain_list.each do |key, value|
    file.worksheet(0).insert_row(row, [key, value.link_title, value.article_link])
    row += 1
  end
  file.write(new_xls_filename)
end

end #end of class DomainScraper


class DomainResult
  attr_accessor :domain, :link_title, :article_link
  def initialize(domain, link_title, article_link)
    @domain = domain
    @link_title = link_title
    @article_link = article_link
  end

end


#Part 2 (unfinished)

#Next Steps: incorporate Moz Api call to get domain authority and spam score; then filter out large sites
#think about how to cleanup results to only get sites with dedicated guest post submission pages

class Mozscape
  attr_reader :moz_da, :moz_spam, :domain
  @moz_access_key = ""
  @moz_secret_key = ""
  @moz_da
  @moz_spam
  @domain

  def initialize(domain)
    @domain = domain
    @moz_da = get_moz_da(domain)
    @moz_spam = get_moz_spam(domain)
  end

  def get_moz_metrics(domain)
      request_url = "https://lsapi.seomoz.com/v2/"
  end
end #end Mozscape class


#implementation example
my_scraper = DomainScraper.new
keyword_list = [ "mantra meditation", "om mani padme hum", "so hum mantra", "guided mantra meditation"]
submission_words = ["write for us", "guest post"]
my_scraper.get_many_search_results(keyword_list, 20, submission_words)
my_scraper.write_results_to_xls('mantra_links.xls', my_scraper.domain_list)
