onraspi = false

require 'watir'
require 'webdrivers' if not onraspi
require 'yaml'
#require 'gmail'
if onraspi
  require 'headless' 
end

class Course
  attr_accessor :name,:code,:page_id,:announcement_ids
end

class Announcement
  attr_accessor :name, :date, :text, :link, :author
end

def names(arr)
  ret = []
  arr.each {|x| ret.push x.name}
  return ret
end

def encode(string)
  string_array = string.scan(/./)
  chr_array = []
  string_array.each do |letter|
    chr_array.push letter.ord
  end
  new_string = ''
  chr_array.each do |chrn|
    if chrn.chr == ' '
      new_string = new_string + '||||'
    end
    chrn = chrn - 32
    chrn = 127 - chrn
    chrn = chrn.chr
    new_string = new_string + chrn
  end
  return new_string
end

if onraspi
  headless = Headless.new
  headless.start
end

password = encode(File.read("../data/password.txt"))

if onraspi
  browser = Watir::Browser.new :firefox
else
  browser = Watir::Browser.new :chrome
end

#=begin
browser.goto("http://nalanda.bits-pilani.ac.in/login/index.php")
browser.link(class: "btn").click
browser.text_field(type: "email").set("f20171176@pilani.bits-pilani.ac.in\n")
browser.text_field(type: "password").set("#{password}\n")
sleep 10
#s=end
sleep 5

courses = YAML.load_stream(File.open("../data/courses.txt"))

courses.each do |c|
  subject = c.code.join("_")
  filename = "../data/#{subject}_announcements.yaml"

  c.announcement_ids.each do |aid|
    url = "http://nalanda.bits-pilani.ac.in/mod/forum/view.php?id=#{aid}"
    sleep 3
    browser.goto(url)
    sleep 5
    next if browser.tables[0].text.include?("Mon Tue Wed Thu Fri Sat Sun") #no announcements
    number_of_announcements = browser.tables[0].children[1].children.size
    File.open(filename, "a") {|f|} #creation if it doesn't exist
    previous_announcements = YAML.load_stream(File.open(filename))
    if previous_announcements==false
      previous_announcements = []
    end
    if previous_announcements.class == Announcement
      prevlen = 1
    else
      prevlen = previous_announcements.length
    end
    if prevlen == 1
      names = previous_announcements[0].name
    else
      names = names(previous_announcements)
    end
    puts "NAMES:"
    p names
    unless (number_of_announcements == prevlen)
      (0..number_of_announcements-1).each do |i|
         current = browser.tables[0].children[1].children[i]
         next if names.include?(current[0].text) #already have read this announcement
         p current[0].text
         new_announcement = Announcement.new()
         new_announcement.name = current[0].text
         new_announcement.author = current[1].text
         sleep 5
         current[0].link.click
         sleep 4
         mainlink = browser.url
         new_announcement.date = browser.div(class:"author").text.split(browser.div(class:"author").child.text)[-1]
         new_announcement.text = browser.div(class:"content").text
         links = []
         obj = browser.div(class:"attachments")
         if obj.present?
           browser.div(class:"attachments").children.each do |posslink|
             if posslink.tag_name == "a" and posslink.text != ""
               links.push [posslink.text,posslink.href]
             end
           end
         end
         new_announcement.link = links
         File.open filename, "a" do |f|
           f.write new_announcement.to_yaml
         end

=begin
         gmail = Gmail.connect!("f20171176@pilani.bits-pilani.ac.in","#{password}")
         gmail.deliver do
           to "f20171176@pilani.bits-pilani.ac.in"
           subject "Nalanda update:#{new_announcement.name}"
           body "#{new_announcement.name}\n #{new_announcement.author}\n#{new_announcement.date}\n#{new_announcement.text}\n#{new_announcement.link}"
         end
         gmail.logout
=end

         `sh ./send-encrypted/send-encrypted.sh -k KGg4T5 -p asdfghjk -s gurupfba -t "Nalanda Update: #{c.name}" -m "#{new_announcement.name}\n#{new_announcement.text}\n #{mainlink}"` #Phone notification - simplepush
         browser.back
      end
    end
  end
end

browser.close()
headless.destroy if onraspi
