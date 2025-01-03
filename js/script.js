function getD() {
    getDeviations('https://backend.deviantart.com/rss.xml?q=favby:forheksed/61076187&limit=10', null, 0);
}

function processDeviations(deviations, hasPrev, hasNext, prevLink, nextLink) {
    $("#loading-spinner").hide();
    for (var i = 0, l = deviations.length; i < l; i++) {
        // var card = 
        // '<div class="col-2 p-2">\
        //   <div class="card">\
        //     <img src="' + deviations[i].thumbM + '" class="card-img-top" alt="...">\
        //     <div class="card-body">\
        //       <h5 class="card-title">' + deviations[i].title + '</h5>\
        //       <details>\
        //         <summary>Description</summary>\
        //         <p class="card-text">' + deviations[i].desc + '</p>\
        //       </details>\
        //       <p class="card-text"></p> \
        //       <a onclick="ahk.OpenLinkInChrome(\'' + encodeURIComponent((deviations[i].image).toString()) + '\')" class="btn btn-primary btn-sm">Open In Chrome</a> \
        //     </div> \
        //   </div> \
        // </div>'
        // ;
        var desc = "";
        if (deviations[i].desc != null) {
            desc = deviations[i].desc;
            desc = desc.split("&lt;")[0];
        } else {
            desc = "";
        }
        var card =
        '<div class="image-container me-2 mb-2">\
          <a class="h-100 w-100" href="' + (deviations[i].image != null ? deviations[i].image : "imgs/no-image.png") + '" data-lightbox="gallery" data-title="' + deviations[i].title + ' - ' + desc + '">\
            <img src="' + (deviations[i].thumbM != null ? deviations[i].thumbM : "imgs/no-image.png") + '" class="" alt="' + deviations[i].title + '" loading="lazy">\
          </a>\
          <div class="copy-link-container">\
            <a class="copy-link-btn" href="' + deviations[i].link + '" target="_blank">Open Link</a>\
            <button class="copy-link-btn" onclick="copy(event)" data-link="' + deviations[i].link + '">Copy Link</button>\
          </div>\
        </div>\
        ';
        $("#images-list").append(card);
    }

    if (hasPrev == true) {
        $("#prev-page").show();
        $("#prev-page").data("nav", prevLink);
        console.log(prevLink);
    } else {
        $("#prev-page").hide();
        $("#prev-page").data("nav", "");
    }

    if (hasNext == true) {
        $("#next-page").show();
        $("#next-page").data("nav", nextLink);
        console.log(nextLink);
    } else {
        $("#next-page").hide();
        $("#next-page").data("nav", "");
    }
}

function Search(event) {
    // console.log(event);
    if (event != undefined && event.target.id == "search-form") {
        event.preventDefault();
    }

    $("#images-list").text("");
    $("#loading-spinner").show();
    var searchTerm = $("#search-input").val();
    var searchLimit = $("#search-limit").val();
    var searchType = $('[name="searchType"]:checked')[0].id;
    var query = "";
    // console.log(searchLimit);

    if (searchTerm != "") {
        // console.log("OK");
        // console.log(searchType);
        if (searchType == "searchByTerm") {
            query = "q=" + searchTerm;
        } else if (searchType == "searchByName") {
            query = "q=by:" + searchTerm;
        } else if (searchType == "searchByGallery") {
            query = "q=gallery:" + searchTerm;
        } else if (searchType == "searchByFavsby") {
            query = "q=favby:" + searchTerm;
        } else if (searchType == "searchByCategory") {
            query = "q=in:" + searchTerm;
        }

        var rssUrl = 'https://backend.deviantart.com/rss.xml?' + query + "&limit=" + searchLimit;
        getDeviations(rssUrl, null, 0);
    } else {
        console.log("Search field is empty!");
        alert("Search field is empty!");
    }

    return false;
}

function goTo(event) {
    // console.log($(event.target).data("nav"));
    $("#images-list").text("");
    $("#loading-spinner").show();
    getDeviations($(event.target).data("nav"), null, 0);
}

function copy(e) {
    e = e || window.event;
    var target = e.target || e.srcElement;

    // console.log(e, target.dataset["link"]);
    var text = target.dataset["link"];
    console.log(text);
    // text = text.replace(/\s+/g, ''); /* remove whitespace */
    document.getElementById('copied').value = text;

    var copyText = document.getElementById("copied");
    copyText.select();
    copyText.setSelectionRange(0, 99999)
    document.execCommand("copy");
    document.getElementById('message').style = "visibility: visible;opacity: 1";
    console.log(document.getElementById('copied').value);
    setTimeout(function () {
        document.getElementById('copied').value = null;
    }, 100);
    setTimeout(function () {
        document.getElementById('message').style = "visibility: hidden;opacity: 0";
    }, 1500);
}