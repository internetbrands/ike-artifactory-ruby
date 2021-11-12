#!env ruby

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'ike_artifactory'

actually_delete = false
if ARGV[0] == '--actually-delete'
  ARGV.shift
  actually_delete = true
end

unless [7, 8].include?(ARGV.count)
  $stderr.puts "Usage: $0 [--actually-delete] artifactory_url repo_key username password application_list image_exclude_list days_to_keep [most_recent_images_to_keep]"
  exit 1
end

artifactory_url = ARGV.shift
repo_key = ARGV.shift
user = ARGV.shift
password = ARGV.shift
application_list = ARGV.shift
image_exclude_list = ARGV.shift
days_to_keep = ARGV.shift.to_i
most_recent_images_to_keep = ARGV.shift.to_i || 10

if days_to_keep <= 7
  $stderr.puts "Invalid number of days_to_keep: #{days_to_keep}"
  exit 2
end

apps = File.readlines(application_list).map &:chomp

unless apps.count
  $stderr.puts "No applications listed in #{application_list}, quitting"
  exit 2
end

images_to_keep = File.readlines(image_exclude_list).each_with_object({}) do |line, keep|
  parts = line.chomp.split(/:/)
  if parts.length == 2
    keep[parts[0]] ||= []
    keep[parts[0]] << parts[1]
  else
    $stderr.puts "Can't parse #{line} as image to keep, aborting"
    exit 3
  end
  keep
end

apps.each do |app|
  puts "Cleaning #{app}"
  cleaner = IKE::Artifactory::DockerCleaner.new(
    actually_delete: actually_delete,
    repo_host: artifactory_url,
    repo_key: repo_key,
    folder: app,
    days_old: days_to_keep,
    tags_to_exclude: images_to_keep[app],
    user: user,
    password: password,
    most_recent_images: most_recent_images_to_keep
  )
  cleaner.cleanup!
end
