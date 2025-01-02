#Requires AutoHotkey v1
#NoEnv
CoordMode, Mouse, Screen
SetBatchLines, -1
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance, force

#Include %A_ScriptDir%\Lib\Neutron.ahk
#Include %A_ScriptDir%\Lib\csv.ahk


neutron := new NeutronWindow()
neutron.Load("index.html")

neutron.Gui("+LabelNeutron")

neutron.Show("w1200 h800")

courseList := []
courseName := ""
GetWindowsDownloadPath()

; FileDelete, courseList.csv
; FileAppend, 
; (
; id, title, link
; ), courseList.csv, UTF-8
; CSV_Load("courseList.csv","data")

return

;@Ahk2Exe-AddResource *10 index.html
;@Ahk2Exe-AddResource *10 %A_ScriptDir%\css\bootstrap.min.css
;@Ahk2Exe-AddResource *10 %A_ScriptDir%\css\neutron.css
;@Ahk2Exe-AddResource *10 %A_ScriptDir%\css\lightbox.min.css
;@Ahk2Exe-AddResource *10 %A_ScriptDir%\js\getDeviations.js
;@Ahk2Exe-AddResource *10 %A_ScriptDir%\js\lightbox.min.js

; The built in GuiClose, GuiEscape, and GuiDropFiles event handlers will work
; with Neutron GUIs. Using them is the current best practice for handling these
; types of events. Here, we're using the name NeutronClose because the GUI was
; given a custom label prefix up in the auto-execute section.
NeutronClose:
    Gui, Cancel
    ; Chrome := new Rufaydium() ; accessing browser
    Chrome.QuitAllSessions() ; closing all session one by one
    Chrome.driver.exit() ; exitting driver
    Sleep, 1000
ExitApp
return

GetCourseLessons(neutron, event)
{
    global Chrome
    global courseList
    global courseName
    Page := "" 
    event.preventDefault()

    neutron.qs("#loading-spinner").style.display := "inline-block"
    url := neutron.qs("#course-url-input").value

    ; Chrome.QuitAllSessions() ; closing all session one by one
    ; Sleep, 1000

    if (Trim(url) != "") {
        courseList := []

        neutron.qs("#course-list").innerHTML := ""

        if(json.dump(Chrome.Sessions()) = [] || json.dump(Chrome.Sessions()) = "[]")
            Page := Chrome.NewSession()
        Else
            Page := Chrome.getSession(1)

        Page.url := url
        Sleep, 2000

        ; Page.NewTab()
        ; Page.Navigate("https://faradars.org/courses/crash-course-of-excel-fvxl01015")

        videoSourcePath := "//*[@id=""faradars-main""]/div[1]/main/div/div/div/div[2]/div/div[4]/div[1]/div[1]/div/div/div/div/video/source[1]"
        videoSourceSelector := "#faradars-main > div.flex.flex-col.w-full.flex-1.transition.ease-linear.duration-150.mt-\[3\.5rem\].md\:\!mt-header-md > main > div > div > div > div.relative.z-0 > div > div.flex.items-start > div.w-full.lgpx\:w-8\/12.lgpx\:pl-2\.5 > div.md\:mx-0 > div > div > div > div > video > source:nth-child(1)"
        courseName := Page.QuerySelector("#faradars-main > div.flex.flex-col.w-full.flex-1.transition.ease-linear.duration-150.mt-\[3\.5rem\].md\:\!mt-header-md > main > div > div > div > div.w-full.flex-nowrap.whitespace-nowrap > nav > div > ol > li:nth-child(5) > span").innerText
        courseName := RegExReplace(courseName, "[<>:\*|\?\\/""]" , "")
        neutron.qs("#course-title").innerText := courseName
        btns := Page.QuerySelectorAll("button[id*=lesson-0-step]")
        csvDir := % A_WorkingDir . "\Courses Data Table\"
        
        Sleep, 1000

        csvFileName := courseName ".csv"
        FileDelete, % csvDir . csvFileName
        FileAppend, 
        (
        id, title, link
        ), % csvDir . csvFileName
        CSV_Load(csvDir . csvFileName, "data")

        Sleep, 1000

        for index, elem in btns
        {
            ; if(index < 2){
                btns[index].Click()
                Sleep, 500

                videoEl := Page.getElementsbyXpath(videoSourcePath)
                videoEl := videoEl[0]
                videoTitle := elem.InnerText
                videoTitle := SubStr(videoTitle, 1, InStr(videoTitle, "`n") - 1)

                if (videoEl.src != "" || Trim(videoEl.src) != ""){
                    courseList.Push({"id": index,"title": RegExReplace(StrReplace(videoTitle, "`n", "_"), "[<>:\*|\?\\/""]" , "-"),"link": videoEl.src})
                    ; Sleep, 200
                    html := neutron.FormatHTML("<li class='list-group-item p-2'><h6>{}</h6><p class='mb-0'><a href='{}' class='d-block text-left'>{}</a></p></li>", (index + 1) "- " videoTitle , videoEl.src, videoEl.src)
                    neutron.qs("#course-list").insertAdjacentHTML("beforeend", html)

                    
                    CSV_AddRow("data", index+1 "," videoTitle "," videoEl.src)
                    ; CSV_ModifyCell("data", "cell" . A_index,6, A_index)
                }
            ; }
            ; Else{
            ;     Break
            ; }
        }

        Sleep, 500
        WinActivate, %A_ScriptName%
        
        neutron.qs("#loading-spinner").style.display := "none"

        if(objLength(courseList) != 0){    
            If( !InStr( FileExist(csvDir), "D") )
                FileCreateDir, Courses Data Table

            CSV_Save(csvDir . csvFileName, "data")

            MsgBox, % "Reading is Done. `n" objLength(courseList) " videos found."
        }
        Else{
            MsgBox, % "Reading is Done. No video found.`n`nPossible causes:`n1.You have entered the course url incorrectly.`n2. You are not logged in to your account.`n3. The video does not exist in your dashboard."
        }
        
    }
    else{
        MsgBox, Fill Course Url
        neutron.qs("#loading-spinner").style.display := "none"
    }
      
}

PasteClipboard(neutron, event)
{
    clipboardLink := Clipboard
    MsgBox, 4, , % "Your clipboard data is: `n" clipboardLink "`n`nWould you like to paste it?"
    IfMsgBox, Yes
        neutron.qs("#course-url-input").value := clipboardLink
    else
        Return
}

DownloadDir(neutron, event)
{
    FileSelectFolder, OutputVar, , 3
    OutputVar := RegExReplace(OutputVar, "\\$")
    if (OutputVar = "")
        MsgBox, You didn't select a folder.
    else
        neutron.qs("#course-download-dir").innerText := OutputVar "\"
}

DownloadCourse(neutron, event)
{
    global courseList
    global courseName
    
    dir := neutron.qs("#course-download-dir").innerText
    
    if(objLength(courseList) != 0){
        MsgBox, 4, , % "You have " objLength(courseList) " videos in your download list.`nDo you want to start downloading?"
        IfMsgBox Yes 
        {        
            DlDir := % dir . courseName
            If(!InStr( FileExist(DlDir), "D"))
                FileCreateDir, % DlDir

            for index, vid in courseList
            {
                ; MsgBox, % vid.link "`n" dir . courseName . "\" . vid.title . ".js"
                ; UrlDownloadToFile, % vid.link, % dir . courseName . "\" . vid.title . ".mp4"
                DownloadFile(vid.link, dir . courseName . "\" . vid.title . ".mp4")
                ; UrlDownloadToFile, https://code.jquery.com/pep/0.4.3/pep.min.js, % dir . vid.title . index . ".min.js"
            }
            MsgBox, The files have been downloaded.
        }
        else
            Return
    }
    else
        MsgBox, Course list is empty!
}

ImportCSV(neutron, event)
{
    global courseList
    global courseName

    FileSelectFile, csvTable , , Courses Data Table, Open Course Data Table, Course Data Table (*.csv)

    if (csvTable = "")
        MsgBox, You didn't select a folder.
    else {
        courseList := []
        neutron.qs("#loading-spinner").style.display := "inline-block"
        neutron.qs("#course-list").innerHTML := ""

        cName := StrSplit(csvTable, "\")
        cName := StrReplace(cName[cName.Length()], ".csv" , "")
        courseName := cName

        neutron.qs("#course-title").innerText := cName

        CSV_Load(csvTable,"data")

        Loop, % CSV_TotalRows("data") - 1
        {
            courseList.Push({"id": CSV_ReadCell("data", A_Index+1, 1),"title": CSV_ReadCell("data", A_Index+1, 2),"link": CSV_ReadCell("data", A_Index+1, 3)})
            ; Sleep, 100
            html := neutron.FormatHTML("<li class='list-group-item p-2'><h6>{}</h6><p class='mb-0'><a href='{}' class='d-block text-left'>{}</a></p></li>", CSV_ReadCell("data", A_Index+1, 1) "- " CSV_ReadCell("data", A_Index+1, 2) , CSV_ReadCell("data", A_Index+1, 3), CSV_ReadCell("data", A_Index+1, 3))
            neutron.qs("#course-list").insertAdjacentHTML("beforeend", html)
        }

        neutron.qs("#loading-spinner").style.display := "none"
        MsgBox, The data table has been imported.
    }
}

Help(neutron, event)
{
    AlertMsg := "If the browser size is in the mobile size mode, Faradars site will create 2 items on the page for each video to make the site responsive, and as a result, 2 download links will be created from each video. So, when the program wants to read the links on the page, set the browser size to a larger size."
    MsgBox, % AlertMsg
}

Test(neutron, event)
{
    global Chrome
    Page := ""  
    
    if(json.dump(Chrome.Sessions()) = [] || json.dump(Chrome.Sessions()) = "[]")
        Page := Chrome.NewSession()
    Else
        Page := Chrome.getSession(1)
    
    Page.url := "https://faradars.org/"
    Sleep, 1000
    
    js = 
    (
        fetch("https://faradars.org/api/v1.1/user/products?type=all&sort=order&direction=desc&limit=100&page=1", {
        "headers": {
            "accept": "application/json",
            "accept-language": "fa",
            "authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiZTdkNjAxMmJlYjMyNDI0ODM2MWEzZWVmYzFhNjY5ZjYwZjNlYmE4MDFjZmMzZDZlZjY3M2Q3NTRjZThlNjdjNjc3MDgxNTI2MDc2ZWM4MDQiLCJpYXQiOjE2ODgzNzMwODEuOTQ2NTg4LCJuYmYiOjE2ODgzNzMwODEuOTQ2NTk4LCJleHAiOjE3MTk5OTU0ODEuOTI2MjIxLCJzdWIiOiIyMDgzNTQiLCJzY29wZXMiOltdfQ.tmqpkr7jQFjGLvLFSrKcszNKe1wfsJbqJDFZEr8q_xsB4gKj-MbwE2C6FHT5y6a7HQqtrsNc47kezinZIX4rYKafTceLxo1nxa2YxtKuXsjKVyBd5dESZlk2wmoFzYAsjwm70XcuW-xh5Wuw16mwvkp78FHHA_fnJCOlOJOTwY1nmDNSvR3S81LeIR0EnKlubDAPreT-t8UfsBo8nh8N7ASLbNYax6e-OVzF3vdp6h0_71DoEXYo2q6A8pE81C3oU_BVIydNJs1CDvoKx7mBgXTZXB5xcTtAKtduuRrEXuSockP97y0nezOWfx2jr_7AkO3BlT2omF_a0Z2KDgQAZ1brVqTzebzKbfA37QsmdNLlQB72NrZMSp5uTKSvOWTADhdkTw8c-8X-zFF43yLtLrCf1MFcfjb8AXXPBnSpIL3d-sZdeJP03VTJY5smrK6oTKSMjI-0HtOoDKNd4xU0634GJin6Z2Bs0p2UTdGfbrz_bINl-1mdUB-8CxOAzmibXRMKS022Vv51oSLI43jthIoiKi-SUgVJAtVrsEcz3ydsVLdHvl_LI8P2oPSg-OeHjN-Fap8jtT-B5HzJ4Fr6oZYF5mJ2ZZdAOK5aX5_tareNMuzxODZvR3nQs2DsI0ApFsmjCS53xeT-_BMDD0NeokDDvKjvyuzQ9OxSbdkTgNo",
            "current-url": "https://faradars.org/my-account",
            "nextjs": "true",
            "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Microsoft Edge\";v=\"114\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "x-xsrf-token": "eyJpdiI6ImhWajRCMkVmUWIxWEthRmlKMlYrUVE9PSIsInZhbHVlIjoidHBVUlcrR2N6eUY5SXlNWHVwRjJOWEg5b2lSS09VbndPWURQbGZRUDR5NTdIaTJYRSs4TEFQM3EyRWYwa2t0dnRLcGgzelFDQ1pxSStJellhSkhwUEZYdGszMVA4Q3ZnbnRwS2RTNWQ2cEhXS0hXVGRaeXI1YkJ2YjFQUTNoclQiLCJtYWMiOiJjNGJkMTY0OTIwOWE5MWYyYTY1NjQxNDczMDdlMmI3MTg2NDdkM2FlOWVjMDAxMDcwMThmMTUyZTJmNzIwYjhjIiwidGFnIjoiIn0="
        },
        "referrer": "https://faradars.org/my-account",
        "referrerPolicy": "strict-origin-when-cross-origin",
        "body": null,
        "method": "GET",
        "mode": "cors",
        "credentials": "include"
        }).then(response => {
        return response.json();
        }).then(data => {
        // Work with JSON data here
            console.log(data.data.products);
            var courses = data.data.products
            var list = ""
            courses.forEach(function(item, index){
                list += index+1 + ", " + item.title + ", " + item.url + "\n"
            });
            console.log(list);
        }).catch(err => {
        // Do something for an error here
        });
    )
    Page.ExecuteSync(js)
    ; data := Page.ExecuteSync(js)
    ; data := Page.ExecuteSync("return 'Hello World!'")
    ; MsgBox, % json.dump(data)
}

GetWindowsDownloadPath()
{
    global neutron
    
    neutron.qs("#course-download-dir").innerText := ComObjCreate("Shell.Application").NameSpace("shell:downloads").self.path "\"
}

objLength(oObj)
{
	return NumGet(&oObj + 4*A_PtrSize)
}

OpenLinkInChrome(neutron, Url)
{
    Url := neutron.wnd.decodeURIComponent(Url)
    ;MsgBox, % Url
	; Run % Url
	; Run, chrome.exe %Url%
	Run, chrome.exe %Url%
    ; neutron.wnd.alert(Url)
    ; neutron.wnd.console.log(neutron.wnd.decodeURIComponent(Url))
	; Run, chrome.exe %Url% " --new-window "
}

DownloadFile(UrlToFile, SaveFileAs, Overwrite := True, UseProgressBar := True)
{
    global neutron

    ;Check if the file already exists and if we must not overwrite it
    If (!Overwrite && FileExist(SaveFileAs))
        Return
    ;Check if the user wants a progressbar
    If (UseProgressBar) {
        ;Initialize the WinHttpRequest Object
        WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        ;Download the headers
        WebRequest.Open("HEAD", UrlToFile)
        WebRequest.Send()
        ;Store the header which holds the file size in a variable:
        FinalSize := WebRequest.GetResponseHeader("Content-Length")
        ;Create the progressbar and the timer
        ; Progress, H80, , Downloading..., %UrlToFile%
        neutron.qs("#download-file-name").innerHTML := UrlToFile
        neutron.qs("#download-progressbar").innerHTML := "<progress id='file' value='" . PercentDone . "' max='100'></progress>"
        SetTimer, __UpdateProgressBar, 100
    }
    ;Download the file
    UrlDownloadToFile, %UrlToFile%, %SaveFileAs%
    ;Remove the timer and the progressbar because the download has finished
    If (UseProgressBar) {
        ; Progress, Off
        neutron.qs("#download-progress-value").innerText := ""
        neutron.qs("#download-file-name").innerText := ""
        neutron.qs("#download-progressbar").innerHTML := ""
        SetTimer, __UpdateProgressBar, Off
    }
    Return

    ;The label that updates the progressbar
    __UpdateProgressBar:
        ;Get the current filesize and tick
        CurrentSize := FileOpen(SaveFileAs, "r").Length ;FileGetSize wouldn't return reliable results
        CurrentSizeTick := A_TickCount
        ;Calculate the downloadspeed
        Speed := Round((CurrentSize/1024-LastSize/1024)/((CurrentSizeTick-LastSizeTick)/1000)) . " Kb/s"
        ;Save the current filesize and tick for the next time
        LastSizeTick := CurrentSizeTick
        LastSize := FileOpen(SaveFileAs, "r").Length
        ;Calculate percent done
        PercentDone := Round(CurrentSize/FinalSize*100)
        ;Update the ProgressBar
        ; Progress, %PercentDone%, %PercentDone%`% Done, Downloading...  (%Speed%), Downloading %SaveFileAs% (%PercentDone%`%)
        neutron.qs("#download-progress-value").innerText := PercentDone "%"
        neutron.qs("#download-progressbar").innerHTML := "<progress id='file' value='" . PercentDone . "' max='100'></progress>"
    Return
}