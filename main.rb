$verbose = ARGV.any? { |arg| arg == "-v" or arg == "--verbose" } or !!ENV["GATS_VERBOSE"]
$criteria = ARGV.any? { |arg| arg == "-c" or arg == "--criteria" } or !!ENV["GATS_CRITERIA"]
$sensitive = ARGV.any? { |arg| arg == "-s" or arg == "--sensitive" } or !!ENV["GATS_SENSITIVE"]

def puts?(message)
  if $verbose
    puts message
  end
end

puts? "Hello from Gats"
puts? "We will get all email contacts and save it on a SQLite database."

source = ENV["QIF_GATS_SOURCE"]
destiny = ENV["QIF_GATS_DESTINY"]

puts? "Getting the e-mails from: #{source}"
puts? "Saving the e-mails on: #{destiny}/emails.db"

$mails = /([a-z][a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/

require "sqlite3"

$sdb = SQLite3::Database.new "#{destiny}/emails.db"
$sdb.execute "CREATE TABLE IF NOT EXISTS emails (email TEXT PRIMARY KEY)"

require "concurrent-ruby"
$pool = Concurrent::FixedThreadPool.new(8)

def is_numeric?(str)
  code = str.ord
  code >= 48 and code <= 57
end

def is_image_link?(name, domain)
  (name.end_with?(".jpg") or name.end_with?(".png")) and is_numeric?(domain[0])
end

def is_image_sized?(domain)
  domain.match?(/\d+x\.(png)|(jpg)/)
end

def is_image(name, domain)
  is_image_sized?(domain) or is_image_link?(name, domain)
end

def is_valid(email)
  at_pos = email.index("@")
  name = email[0..at_pos - 1]
  domain = email[at_pos + 1..]
  if name.size > 30 or domain.size > 60
    return false
  end
  if is_image name, domain
    return false
  end
  syllables = name.split(/[aeiou._-]/)
  weird_letters = 0
  usual_letters = 0
  syllables.each do |syllable|
    if syllable.size > 3
      weird_letters = weird_letters + syllable.size
    else
      usual_letters = usual_letters + syllable.size + 2
    end
  end
  if weird_letters > usual_letters
    return false
  end
  return true
end

def save_to_sqlite(email)
  begin
    $sdb.execute "INSERT INTO emails (email) VALUES (?)", email
    puts? "Saved: #{email}"
  rescue
  end
end

$usual = []
$weird = []
$check = []

def get_from(file)
  reader = File.open(file)
  data = reader.read
  founds = data.scan($mails)
  for found in founds
    for email in found
      email = email.downcase
      if is_valid(email)
        save_to_sqlite(email)
        if $criteria
          if not $usual.include? email
            puts "Usual: #{email}"
            $usual.push email
          end
        end
      else
        if $criteria
          if not $weird.include? email
            puts "Weird: #{email}"
            $weird.push email
          end
        end
        if $sensitive and email.size < 30
          if not $check.include? email
            puts "Check: #{email}"
            $check.push email
          end
        end
      end
    end
  end
end

def traverse(path)
  Dir.entries(path).each do |name|
    if name == "." || name == ".." then next end
    concat = File.join(path, name)
    puts? "Found: #{concat}"
    if File.directory? concat
      traverse(concat)
    else
      $pool.post do get_from(concat) end
    end
  end
end

if caller.length == 0
  traverse(source)
end
