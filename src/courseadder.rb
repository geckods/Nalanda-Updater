require 'watir'
require 'webdrivers'
require 'yaml'

def type(str)
  str.each_char do |c|
    print c
    sleep 0.05
  end
  puts
end

filename = "../data/courses.txt"

class Course
  attr_accessor :name,:code,:page_id,:announcement_ids
end

if not File.exist?(filename)
  File.open(filename, "w")
end

courses = YAML.load_stream(File.open(filename))

if courses.empty?
  type "You have no courses added so far."
else
  type "You have added #{courses.length} courses so far."
  courses.each do |c|
    type c.name + ":" + c.code.join(" ")
  end
end

type "What course would you like to add? (Type in the Course name)"
name = gets.chomp

type "Please enter the course code. Enter in the following format:'XX FYYY', where XX is the department code, and YYY is the course number."
code = gets.chomp.upcase.split(" ")
#code = "(" + code + ")"

courses.each do |z|
  if z.code == code
    type "That course code already exists! Exiting program."
    exit
  end
end

type "Obtaining course numbers... Please wait."

b = Watir::Browser.new :firefox
b.goto("http://nalanda.bits-pilani.ac.in/course/search.php?search=%28#{code[0]}+#{code[1]}%29")

page_id = b.div(class: ["coursebox clearfix odd first last"]).attribute_value("data-courseid")

b.goto("http://nalanda.bits-pilani.ac.in/course/view.php?id=#{page_id}")

announcement_ids = []

announcelist = b.elements(class: ["activity forum modtype_forum"]).to_a
announcelist.each do |possann|
  if possann.text.downcase.include?("announcement")
    announcement_ids.push possann.attribute_value("id").split("-")[-1]
  end
end

c = Course.new
c.name = name
c.code = code
c.page_id = page_id
c.announcement_ids = announcement_ids

b.close
type "Done Obtaining Course Details"
type "Please Verify The Following Information"

type "Name:#{name}\nCode:#{code}\nPage_id:#{page_id}\nAnnouncement_ids:#{announcement_ids}"
type "(Y/N)"

if gets.chomp.downcase != "y"
  type "Course addition unsuccessful, exiting program."
  exit
end

type "Ok, adding course."
File.open(filename,"a") do |f|
  f.write c.to_yaml
end

File.open("../data/#{c.code.join("_")}_announcements.yaml","w") {}
File.open("../data/#{c.code.join("_")}_data.yaml","w") {}
type "Course addition successful!"
