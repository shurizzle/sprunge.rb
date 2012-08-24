#
# sprunge.rb: ruby clone of http://sprunge.us, see
# https://github.com/rupa/sprunge
#
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details. 
#

require 'sinatra'
require 'mongo'
require 'coderay'

domain = 'localhost:4567'
post_key = 'localhost' 
database = 'sprunge'
entries = 10 

collection = Mongo::Connection.new.db(database)['sprunge']

get '/' do
	# show your homepage here
	redirect to('http://www.google.com')
end

get %r{^/([A-Za-z0-9\-_]{16})$} do |base64_id|
	# decode the id
	id = BSON::ObjectId.new(Base64.urlsafe_decode64(base64_id).bytes.to_a)
	document = collection.find(:_id => id).first

	text = document['text']
	lang = request.GET.keys.first
	
	if document and lang
		body CodeRay::Duo[lang, :div].highlight(text)
	elsif document
		headers 'Content-Type' => 'text/plain'
		body text
	else
		redirect to('/')
	end
end

post '/' do
	if collection.find.count >= entries
		# find and remove the oldest document
		document = collection.find.sort([:date, :desc]).first
		collection.remove(document)
	end

	# insert the new document 
	document = {:date => Time.now, :text => request.POST[post_key]} 
	id = collection.insert(document)
	# get the encoded id
	base64_id = Base64.urlsafe_encode64(id.to_a.map{ |i| i.chr }.join)
	response_url = 'http://' + domain + '/' + base64_id + "\n"

	headers 'Content-Type' => 'text/plain'
	body response_url
end

