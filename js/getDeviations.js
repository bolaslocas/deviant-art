function getDeviations(url, limit, start) {
    var deviations = [];
    var url = url || 'https://backend.deviantart.com/rss.xml?q=gallery:dark-necrodevourer';
    var limit = limit || null;
    var start = start || 0;

    let xhr = new XMLHttpRequest();
    xhr.open('GET', url);
    xhr.send();

    xhr.onload = function () {
        try {
            let json1 = xml2json(new DOMParser().parseFromString(xhr.response, 'text/xml'));
            let json2 = JSON.parse('{' + json1.slice(11));
            let items = json2.rss.channel.item;

            let pagination = json2.rss.channel["atom:link"];
            let hasPrev = false, hasNext = false;
            let prevLink = null, nextLink = null;

            if (pagination?.length) {
                for (let p of pagination) {
                    if (p['@rel'] === "next") nextLink = p['@href'], hasNext = true;
                    if (p['@rel'] === "previous") prevLink = p['@href'], hasPrev = true;
                }
            }

            if (items) {
                for (let i = 0, l = items.length; i < l; i++) {
                    if (i < start) continue;
                    if (limit && i >= start + limit) break;

                    let item = items[i];
                    let category = item['media:category']?.['#text'] || 'all';

                    // Filtrar solo los de la categoría 'all'
                    if (category.toLowerCase() !== 'all') continue;

                    // Solo si hay imagen de alta resolución
                    let imageUrl = item['media:content']?.['@url'];
                    if (!imageUrl || !imageUrl.includes('orig')) continue;

                    let deviation = {
                        title: item.title,
                        link: item.link,
                        date: item.pubDate,
                        desc: item['media:description']?.['#text'],
                        thumbS: item['media:thumbnail']?.[0]?.['@url'],
                        thumbM: item['media:thumbnail']?.[1]?.['@url'],
                        thumbL: item['media:thumbnail']?.[2]?.['@url'],
                        image: imageUrl,
                        download: imageUrl,
                        rating: item['media:rating'],
                        category: category,
                        categoryUrl: 'https://www.deviantart.com/' + category,
                        deviantName: item['media:credit']?.[0]?.['#text'],
                        deviantAvatar: item['media:credit']?.[1]?.['#text'],
                        deviantUrl: item['media:copyright']?.['@url'],
                        copyright: item['media:copyright']?.['#text']
                    };

                    deviations.push(deviation);
                }
            }

            processDeviations(deviations, hasPrev, hasNext, prevLink, nextLink);
        } catch (error) {
            console.error('Parsing error:', error);
            alert("Error processing DeviantArt feed.");
        }
    };
}
