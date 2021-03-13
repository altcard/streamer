#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'time'

def read_settings
	contents = { "output" => "/tmp/cam.jpeg",
		     "source" => "/dev/video0",
		     "socket" => "/tmp/trigger.txt",
		     "interval" => 0.3,
		     "fork" => true }
	confPath = File.join(File.dirname(__FILE__), "config.json")

	if File.exists? confPath then
		contents.merge! JSON.parse(File.read(confPath))
	else
		puts "Using the pre-defined settings (#{confPath} does not exist)"
	end

	return contents
end

def valid_to_continue?(settings)
	if settings['socket'] == false then
		return true # true until explicitly stopped
	else
		return File.exists?(settings['socket'])
	end
end

def init_socket(settings)
	if settings['socket'] == false then
		return
	end


	File.write(settings['socket'], DateTime.now.to_s)
end

def crash_with_socket_deinit(settings)
	if File.exists? settings['socket'].to_s then
		FileUtils.rm_f(settings['socket'])
	end

	puts "Crashed, goodbye"
	exit 1
end

def event_loop(settings)
	while valid_to_continue? settings
		system("streamer", "-c", settings['source'], "-f", "jpeg", "-o", settings['output']) or crash_with_socket_deinit(settings)
		sleep settings['interval']
	end
end

settings = read_settings
init_socket(settings)

puts settings

if settings.keys.include?("fork") and settings["fork"] then
	if settings['socket'] == false then
		puts "Forking without a valid socket file is not supported for obvious reasons I have no need to explain to you"
		crash_with_socket_deinit(settings)
	end

	puts "Forking Streamer into a seperate process (delete #{settings['socket']} to stop)"
	pid = fork do
		at_exit do
			FileUtils.rm_f(settings['socket'])
		end

		event_loop(settings)
	end

	puts "PID #{pid}"
else
	puts "Running in-place"
	event_loop(settings)
end

puts "Goodbye"
