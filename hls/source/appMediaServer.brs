'********************************************************************
'**  MediaPlayer Application - Main
'********************************************************************

'******************************************************
'** Display a scrolling grid of everything on the server
'******************************************************
Function homeScreen(has_keystore As Boolean)
  port = CreateObject("roMessagePort")
  categories = CreateObject("roPosterScreen")
  categories.SetMessagePort(port)
  categories.SetBreadcrumbText("hls Media Player","Home")
  list = CreateObject("roArray", 4, true)

  ' Category#1 content
  o = CreateObject("roAssociativeArray")
  o.Title = "MediaServers"
  o.ShortDescriptionLine1 = "Media Server"
  o.Description = "Browse media server contents"
  o.HDPosterUrl = "pkg:/images/MediaServer.png"
  o.SDPosterUrl = "pkg:/images/MediaServer.png"
  list.Push(o)
  ' Category#2 content
  o = CreateObject("roAssociativeArray")
  o.Title = "Live Stream"
  o.ShortDescriptionLine1 = "Live Stream"
  o.Description = "Stream content using HTTP Live Stream"
  o.HDPosterUrl = "pkg:/images/Stream.png"
  o.SDPosterUrl = "pkg:/images/Stream.png"
  list.Push(o)
  ' Category#3 content
  o = CreateObject("roAssociativeArray")
  o.Title = "Search"
  o.ShortDescriptionLine1 = "Search"
  o.Description = "Search media"
  o.HDPosterUrl = "pkg:/images/Search.png"
  o.SDPosterUrl = "pkg:/images/Search.png"
  list.Push(o)
  ' Category#4 content
  o = CreateObject("roAssociativeArray")
  o.Title = "Settings"
  o.ShortDescriptionLine1 = "Settings"
  o.Description = "Configuration setup"
  o.HDPosterUrl = "pkg:/images/Settings.png"
  o.SDPosterUrl = "pkg:/images/Settings.png"
  list.Push(o)
  categories.SetListDisplayMode("scale-to-fill")
  categories.SetListStyle("flat-category")
  categories.SetFocusToFilterBanner(true)
  categories.SetContentList(list)
  categories.Show()
  screen = invalid

  While True
     msg = wait(0, port)
     If msg.isScreenClosed() Then
         return -1
     ElseIf msg.isListItemSelected()
         If msg.GetIndex() = 0 Then
            print "msg: ";msg.GetMessage();"idx0: ";msg.GetIndex()
            screen = mediaServer("http://"+RegRead("ServerURL"), has_keystore)
         ElseIf msg.GetIndex() = 1 Then
             print "msg: ";msg.GetMessage();"idx1: ";msg.GetIndex()
             url = "http://"+RegRead("ServerURL")
             if url <> invalid then
                result = displaySaveVideo(url)
             else
                dialog = CreateObject("roMessageDialog")
                dialog.SetTitle("Missing MediaServer URL")
                dialog.SetText("Go to Settings and select a media server")
                dialog.AddButton(1, "Done")
                dialog.EnableBackButton(true)
                dialog.Show()
             end if
         ElseIf msg.GetIndex() = 2 Then
             print "msg: ";msg.GetMessage();"idx2: ";msg.GetIndex()
             if screen <> invalid then
                searchScreen(screen)
             else
                dialog = CreateObject("roMessageDialog")
                dialog.SetTitle("Missing MediaServer library")
                dialog.SetText("Load the media server by selecting mediaServer once")
                dialog.AddButton(1, "Done")
                dialog.EnableBackButton(true)
                dialog.Show()
             end if
         ElseIf msg.GetIndex() = 3 Then
             print "msg: ";msg.GetMessage();"idx3: ";msg.GetIndex()
             checkServerUrl(true)
         End If
     End If
  End While
End Function


Function mediaServer( url As String, has_keystore As Boolean ) As Object
    print "Starting media server successful";
    port=CreateObject("roMessagePort")
    poster = CreateObject("roPosterScreen")
    poster.SetMessagePort(port)
    poster.SetListDisplayMode("scale-to-fill")
    poster.SetListStyle("arced-landscape")
    ' Build list of Category Names from the top level directories
    listing = getDirectoryListing(url+"/movies")
    if listing = invalid then
        print "Failed to get directory listing for ";url
        return invalid
    end if
    displayList = displayFiles(listing, { mp4 : true, m4v : true, mov : true, wmv : true } )
    print "Directory listing generated successful";
    ' Hold all the movie objects
    screen = CreateObject("roArray", displayList.Count()+1, false)
    loadingDialog = ShowPleaseWait("Loading Movies...", "")
    total = 0
    listing_hash = CreateObject("roAssociativeArray")
    for each f in listing
        listing_hash.AddReplace(f, "")
    end for
    total = total + displayList.Count()
    Sort(displayList, function(k)
                       return LCase(k[0])
                      end function)
    loadingDialog.SetTitle("Loading Movie# "+Stri(total))
    list = CreateObject("roArray", displayList.Count(), false)
    for j = 0 to displayList.Count()-1
        cat_url = url + "/movies/"
        list.Push(MovieObject(displayList[j], cat_url, listing_hash))
    end for
    poster.SetContentList(list)
    poster.SetBreadcrumbText("Home","Media Server library")
    poster.SetBreadcrumbEnabled(true)
    screen.Push(list)
    loadingDialog.Close()
    poster.show()
    while true
        msg = wait(30000, port)
        if type(msg) = "roPosterScreenEvent" then
            if msg.isScreenClosed() then
                return -1
            else if msg.isListItemSelected() then
                    if has_keystore = true then
                        setKeyValue(url, getLastElement(categories[msg.GetIndex()-1][0]), tostr(msg.GetData()))
                    end if
                    smovie = screen[0][msg.GetIndex()]
                    result = playMovie(smovie, url , has_keystore)
                    print "Result of play movie "; result
                    if result = true and msg.GetData() < screen[msg.GetIndex()].Count() then
                        ' Advance to the next video and save it
                        grid.SetFocusedListitem(msg.GetIndex(), msg.GetData()+1)
                        if has_keystore = true then
                            setKeyValue(url, getLastElement(categories[msg.GetIndex()-1][0]), tostr(msg.GetData()+1))
                        end if
                    end if
            end if
        end if
    end while
    return screen
End Function

'******************************************
'** Create an object with the movie metadata
'******************************************
Function MovieObject(file As Object, url As String, listing_hash as Object) As Object
    o = CreateObject("roAssociativeArray")
    r = CreateObject("roRegex", "%20", "i")
    o.ContentType = "movie"
    o.Title = r.ReplaceAll(file[1]["basename"]," ")
    o.ShortDescriptionLine1 = o.Title

    ' Search for SD & HD images and .bif files
    if listing_hash.DoesExist(file[1]["basename"]+"-SD.png") then
        o.SDPosterUrl = url+file[1]["basename"]+"-SD.png"
    else if listing_hash.DoesExist(file[1]["basename"]+"-SD.jpg") then
        o.SDPosterUrl = url+file[1]["basename"]+"-SD.jpg"
    else
        o.SDPosterUrl = "pkg:/images/default-SD.png"
    end if

    o.IsHD = true
    ' On the Roku 2 (and 3?) if IsHD is false having HDPosterUrl set interferes with
    ' displaying the correct SDPosterUrl. Disable this for now, since it isn't really
    ' used at all.
    if listing_hash.DoesExist(file[1]["basename"]+"-HD.png") then
        o.HDPosterUrl = url+file[1]["basename"]+"-HD.png"
    else if listing_hash.DoesExist(file[1]["basename"]+"-HD.jpg") then
        o.HDPosterUrl = url+file[1]["basename"]+"-HD.jpg"
    else
        o.HDPosterUrl = "pkg:/images/default-HD.png"
    end if
    if listing_hash.DoesExist(file[1]["basename"]+"-SD.bif") then
        o.SDBifUrl = url+file[1]["basename"]+"-SD.bif"
    end if
    if listing_hash.DoesExist(file[1]["basename"]+"-HD.bif") then
        o.HDBifUrl = url+file[1]["basename"]+"-HD.bif"
    end if
    if listing_hash.DoesExist(file[1]["basename"]+".txt") then
        o.Description = getDescription(url+file[1]["basename"]+".txt")
    end if

    o.HDBranded = false
    o.Rating = "NR"
    o.StarRating = "NR"
    o.Length = 0

    ' Video related stuff (can I put this all in the same object?)
    o.StreamBitrates = [0]
    o.StreamUrls = [url+file[0]]
    o.StreamQualities = ["SD"]

    streamFormat = { mp4 : "mp4", m4v : "mp4", mov : "mp4",
                     wmv : "wmv", hls : "hls"
                   }
    if streamFormat.DoesExist(file[1]["extension"].Mid(1)) then
        o.StreamFormat = streamFormat[file[1]["extension"].Mid(1)]
    else
        o.StreamFormat = ["mp4"]
    end if

    return o
End Function

'*************************************
'** Get the last position for the movie
'*************************************
Function getLastPosition(title As String, url As String, has_keystore As Boolean) As Integer
    ' use movie.Title as the filename
    last_pos = ReadAsciiFile("tmp:/"+title)
    if last_pos <> "" then
        return last_pos.toint()
    end if
    ' No position stored on local filesystem, query keystore
    if has_keystore = true then
        last_pos = getKeyValue(url, title)
        if last_pos <> "" then
            return last_pos.toint()
        end if
    end if
    return 0
End Function

'******************************************************
'** Return a list of the Videos and directories
'**
'** Videos end in the following extensions
'** .mp4 .m4v .mov .wmv
'******************************************************
Function displayFiles( files As Object, fileTypes As Object, dirs=false As Boolean ) As Object
        list = []
    for each f in files
        ' This expects the path to have a system volume at the start
        p = CreateObject("roPath", "pkg:/" + f)
        if p.IsValid() and f.Left(1) <> "." then
            fileType = fileTypes[p.Split().extension.mid(1)]
            if (dirs and f.Right(1) = "/") or fileType = true then
                list.push([f, p.Split()])
            end if
        end if
    end for
    return list
End Function

'******************************************************
'** Play the video using the data from the movie
'** metadata object passed to it
'******************************************************
Sub playMovie(movie As Object, url As String, has_keystore As Boolean) As Boolean
    Print "Movie play has started";
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    video.SetPositionNotificationPeriod(15)
    movie.PlayStart = getLastPosition(movie.Title, url, has_keystore)
    video.SetContent(movie)
    video.show()
    last_pos = 0
    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                exit while
            else if msg.isPlaybackPosition() then
                last_pos = msg.GetIndex()
                WriteAsciiFile("tmp:/"+movie.Title, tostr(last_pos))
                if has_keystore = true then
                    setKeyValue(url, movie.Title, tostr(last_pos))
                end if
            else if msg.isfullresult() then
                DeleteFile("tmp:/"+movie.Title)
                if has_keystore = true then
                    setKeyValue(url, movie.Title, "")
                end if
                return true
            else if msg.isRequestFailed() then
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while
    Print "Play has ended";
    return false
End Sub

'******************************************************
'** Another version of video player
'** Play the video using the data from the movie
'** metadata object passed to it
'******************************************************
Function displaySaveVideo(url As String)
    Print "HTTP live stream play has started";
    print "Stream URL: "; url
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    bitrates  = [0]

    ' Apple's HLS test stream
    'http://techslides.com/demos/sample-videos/small.mp4
    'http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
    urls = ["http://devimages.apple.com/iphone/samples/bipbop/gear4/prog_index.m3u8"]
    qualities = ["SD"]
    streamformat = "hls"
    title = "Apple BipBop Test Stream"
    srt = ""

    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = StreamFormat
    videoclip.Title = title
    print "srt = ";srt
    if srt <> invalid and srt <> "" then
        videoclip.SubtitleUrl = srt
    end if

    connStream = CreateObject("roUrlTransfer")
    portStream = CreateObject("roMessagePort")
    connStream.SetMessagePort(portStream)
    urlToStream = "http://devimages.apple.com/iphone/samples/bipbop/gear4/prog_index.m3u8"
    connStream.SetUrl(urlToStream)
    connStream.SetRequest("GET")

    cut_url = "http://devimages.apple.com/iphone/samples/bipbop/gear4/"
    connPC = CreateObject("roUrlTransfer")
    portPC = CreateObject("roMessagePort")
    connPC.SetMessagePort(portPC)
    urlPC = url+":8080/saveVideo"
    print "urlPC: "; urlPC
    connPC.SetUrl(urlPC)
    connPC.SetRequest("POST")

    video.SetContent(videoclip)
    video.show()
    streamlist = getStreamList(connStream)
    streamlist_len = streamlist.Count()
    index = 0
    print "type:"; Type(streamlist)
    print "------------configuration done successfully-------------"

    while true
        msg = wait(0, video.GetMessagePort())
        'print "Message: "; msg
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                print "isPlaybackPosition"
                nowpos = msg.GetIndex()
                if nowpos > 10000
                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed() then
                print "play failed: "; msg.GetMessage()
            else if msg.isStreamStarted() then
                saveVideo(0, cut_url, streamlist, connStream, connPC)
            else if msg.isStreamSegmentInfo() then
                index = msg.GetIndex() / 10000
                saveVideo(index+1, cut_url, streamlist, connStream, connPC)
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while

    urlPC = url+":8080/bye"
    urlPC.Trim()
    connPC.SetUrl(urlPC)
    statusPC = connPC.PostFromString("bye")
    print "ASyncPostFromFile: "; statusPC
    print "urlPC: "; urlPC

    return false
End Function

'******************************************************
'** Parse m3u8 playlist to create a list of stream segments
'** and read it into a list.
'******************************************************
Function getStreamList(connStream As Object) As Object
    status = connStream.GetToFile("tmp:/playlist.m3u8")
    text_playlist = ReadAsciiFile("tmp:/playlist.m3u8")
    playlist_obj = CreateObject("roString")
    playlist_obj.SetString(text_playlist)
    playlist_array = playlist_obj.Tokenize(chr(10))
    streamlist = CreateObject("roList")
    for each stream in playlist_array
      if Instr(1, stream, "#") <> 1
          streamlist.push(stream)
          print stream
      end if
    end for
    return streamlist
End Function

'******************************************************
'** Parse m3u8 playlist to create a list of stream segments
'** and read it into a list.
'******************************************************
Function saveVideo( index As Integer, cut_url As String, streamlist As Object, connStream As Object, connPC As Object)
    connStream.SetUrl(cut_url+streamlist[index])
    print "URL: "; connStream.GetUrl()
    status = connStream.GetToFile("tmp:/sample.ts")
    'print "ASyncGetToFile: "; status
    statusPC = connPC.PostFromFile("tmp:/sample.ts")
    'print "ASyncPostFromFile: "; statusPC
End Function

'******************************************************
'** Check to see if a description file (.txt) exists
'** and read it into a string.
'** And if it is missing return ""
'******************************************************
Function getDescription(url As String)
    http = CreateObject("roUrlTransfer")
    http.SetUrl(url)
    resp = http.GetToString()

    if resp <> invalid then
        return resp
    end if
    return ""
End Function
