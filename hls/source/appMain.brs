'********************************************************************
'**  MediaPlayer Application
'********************************************************************
Sub Main()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()
    ' Get server url and make sure it is valid
    valid_dir = false
    force_edit = false
    while not valid_dir
        valid_dir = checkServerUrl(force_edit)
        'dir = getDirectoryListing( "http://"+RegRead("ServerURL") )
        'if dir = invalid then
        ''    force_edit = true
        ''    valid_dir = false
        'end if
    end while
    ' Check to see if the server supports keystore
    has_keystore = isUrlValid("http://"+RegRead("ServerURL")+"/keystore/version")
    'home screen Setup
    homeScreen(has_keystore)

End Sub


'*************************************************************
'** Set the configurable theme attributes for the application
'**
'** Configure the custom overhang and Logo attributes
'** Theme attributes affect the branding of the application
'** and are artwork, colors and offsets specific to the app
'*************************************************************
Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/Overhang_Logo_HD.png"
    theme.OverhangOffsetHD_X = "85"
    theme.OverhangOffsetHD_Y = "30"
    theme.OverhangSliceSD = "pkg:/images/Overhang_Background_SD.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/Overhang_Logo_SD.png"
    theme.OverhangOffsetSD_X = "70"
    theme.OverhangOffsetSD_Y = "30"
    theme.BackgroundColor = "#1a1a1a"
    'theme.GridScreenOverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    'theme.GridScreenLogoHD = "pkg:/images/Overhang_Logo_HD.png"
    'theme.GridScreenOverhangHeightHD = "90"
    'theme.GridScreenBackgroundColor = "#1a1a1a"
    'theme.GridScreenLogoOffsetHD_X = "70"
    'theme.GridScreenLogoOffsetHD_Y = "17"
    app.SetTheme(theme)
End Sub
