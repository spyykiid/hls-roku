#!/usr/bin/env python
import web
import time
import os
from ffmpy import FF

#defining routes
urls = (
	"/", "Hello",
       "/bye", "Bye",
       "/saveVideo","Save"
	)

#Define a web application with the routes specified above
app = web.application(urls, globals())

#input source and output destination are defined
input = '/var/www/movies/sample.ts'
output = '/var/www/movies/live_stream'
file_stream = open(input, "wb")
file_format = '.mp4'
file_close = False


class Hello:
    def __init__(self):
        pass
    def GET(self):
        return 'Hello, User!'

# After streaming is stopped build the mp4 formatted file and clean up the input
class Bye:
    def POST(self):
	global file_close
        file_stream.close()
        ff = FF(inputs={input: None}, outputs={output+time.strftime("%d-%m-%Y_%H.%M.%S")+file_format: None})
        ff.run()
        os.remove(input)
        print file_stream
	file_close = True

# Save incoming source to a persistent storage
class Save:
    def POST(self):
	global file_close
	if file_close:
           global file_stream
           file_stream = open(input,"wb")
	data = web.data()
        '''print data'''
        file_stream.write(data)

# Run the application
if __name__ == "__main__":
    app.run()

