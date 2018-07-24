//from biocache-service colorUtil, plus other websafe colours (more than 100, which is current max on records-per-page)
var colours = [/* colorUtil */ "8B0000", "FF0000", "CD5C5C", "E9967A", "8B4513", "D2691E", "F4A460", "FFA500", "006400", "008000", "00FF00", "90EE90", "191970", "0000FF",
    "4682B4", "5F9EA0", "00FFFF", "B0E0E6", "556B2F", "BDB76B", "FFFF00", "FFE4B5", "4B0082", "800080", "FF00FF", "DDA0DD", "000000", "FFFFFF",
    /* websafe */ "CC6699", "660066", "9966CC", "CCCCFF", "0099CC", "993366", "990099", "990033", "00CC66", "0033FF", "999966", "FF0099", "FF6600",
    "CC6633", "66CC99", "CCFFCC", "99CC00", "330000", "660033", "FF3300", "FF0033", "330066", "CC3366", "3300CC", "339966", "FFFF99", "669966",
    "663333", "33FF66", "33FFFF", "999933", "00FFCC", "33CC99", "FF0066", "3366CC", "0033CC", "66CC00", "663399", "993399", "99CC33", "660000",
    "3333CC", "CCFF33", "6633FF", "66FFFF", "00CC99", "003399", "9966FF", "996699", "33FF00", "CC99CC", "FF99CC", "6699FF", "6666CC", "FF9966",
    "003333", "6633CC", "FF33CC", "669933", "FFCC33", "FFCCCC", "33FF33", "CCCC00", "99CCFF", "330099", "FF33FF", "663300", "FFFFCC", "66FF00",
    "339933", "FF00CC", "00CCFF", "CC6666", "66CCFF", "336699", "009933", "33FF99", "009900", "CC3300", "333333", "CC0000", "99CC99", "0066FF",
    "99FFFF", "66FFCC", "FF3333", "CC99FF", "FF9900", "CCCC66", "660099", "FFCC99", "3366FF", "FF6633", "990066", "CC66FF", "00CC33", "00CC00",
    "333300", "009966", "CC0033", "CC3333", "339999", "CC33FF", "CC0066", "FFCC00", "CC00FF", "CCFF66", "9999CC", "00FF66", "666633", "003300",
    "993300", "996633", "993333", "FFCCFF", "000066", "99FF00", "FF6666", "FF9933", "3399FF", "66CC66", "CC9966", "999900", "3333FF", "6600FF",
    "CC00CC", "66FF66", "99FF66", "669900", "6666FF", "990000", "3300FF", "CC33CC", "CCFFFF", "9999FF", "999999", "330033", "CC0099", "000033",
    "339900", "CC9933", "33CC00", "FF3366", "FF3399", "009999", "FFCC66", "333366", "99FF33", "CC6600", "33CCCC", "663366", "336666", "CCFF00",
    "666666", "003366", "0099FF", "336633", "CCCC33", "CC66CC", "66FF33", "336600", "006699", "00CCCC", "000099", "9933FF", "FF6699", "66FF99",
    "9933CC", "FF99FF", "996600", "33FFCC", "66CC33", "006600", "99CCCC", "3399CC", "0066CC", "33CC66", "99FF99", "33CC33", "6699CC", "666699",
    "FF66CC", "CC3399", "9900CC", "CC9900", "CC9999", "669999", "FF66FF", "00FF33", "FFFF33", "CCFF99", "CCCCCC", "66CCCC", "996666", "006633",
    "FFFF66", "9900FF", "00FF99", "333399", "99FFCC", "666600", "33CCFF", "006666", "0000CC", "6600CC", "CCCC99", "FF9999", "99CC66"
];

//adapted from sliderProUtils function of same name
function checkIE() {
    if ( typeof checkIE.isIE !== 'undefined' ) {
        return checkIE.isIE;
    }

    var userAgent = window.navigator.userAgent,
        msie = userAgent.indexOf( 'MSIE' );
    if ( userAgent.indexOf( 'MSIE' ) !== -1 || userAgent.match( /Trident.*rv\:11\./ ) ) {
        checkIE.isIE = true;
    } else {
        checkIE.isIE = false;
    }

    return checkIE.isIE;
}

function loadTheMap (MAP_CONF) {
    if (MAP_CONF.showResultsMap) {
        MAP_CONF.resultsToMapJSON = JSON.parse($('<textarea/>').html(MAP_CONF.resultsToMap).text());

        var firstMapShow = true;
        var isIE = checkIE();
        //leaflet maps don't like being loaded in a div that isn't being shown, this fixes the position of the map
        $(function () {
            if (MAP_CONF.mapType == 'search') {
                $("#tabs").tabs({
                    beforeActivate: function (event, ui) {
                        if (firstMapShow) {
                            firstMapShow = false;
                            if (!isIE) {
                                window.dispatchEvent(new Event('resize'));
                            } else {
                                var event = document.createEvent("Event");
                                event.initEvent("resize", false, true);
                                // args: string type, boolean bubbles, boolean cancelable
                                window.dispatchEvent(event);
                            }
                            fitMapToBounds(MAP_CONF);
                        }
                    }
                });
            }
            removeMap(MAP_CONF);
            loadMap(MAP_CONF);
            setMapTitle(MAP_CONF);
            if (!isIE) {
                window.dispatchEvent(new Event('resize'));
            } else {
                var event = document.createEvent("Event");
                event.initEvent("resize", false, true);
                // args: string type, boolean bubbles, boolean cancelable
                window.dispatchEvent(event);
            }
        });
    }
}

function initialPresenceAbsenceMap(MAP_CONF, searchResultsPresence, searchResultsAbsence) {
    if ($('input[name=toggle]:checked', '#map-pa-switch').val() == 'absence') {
        MAP_CONF.resultsToMap = searchResultsAbsence;
        MAP_CONF.presenceOrAbsence = "absence";
    } //else default is presence map
}

function setPresenceAbsenceToggle(MAP_CONF, searchResultsPresence, searchResultsAbsence) {
    $('input[name=toggle]', '#map-pa-switch').change(function() {
        var toggle = this.value;
        if (toggle == 'absence') {
            /* toggleContainer.style.backgroundColor = '#D74046'; */
            MAP_CONF.resultsToMap = searchResultsAbsence;
            MAP_CONF.presenceOrAbsence = "absence";
            removeMap(MAP_CONF);
            loadTheMap(MAP_CONF);

        } else if (toggle == 'presence') {
            /* toggleContainer.style.backgroundColor = 'dodgerblue'; */
            MAP_CONF.resultsToMap = searchResultsPresence;
            MAP_CONF.presenceOrAbsence = "presence";
            removeMap(MAP_CONF);
            loadTheMap(MAP_CONF);
        }
    });
}

function removeMap(MAP_CONF) {
    if(MAP_CONF.map) {
        MAP_CONF.map.remove();
        MAP_CONF.map.off();
        delete MAP_CONF.map;
    }
}

//not currently used:

var clickCount = 0;

/**
 * Fudge to allow double clicks to propagate to map while allowing single clicks to be registered
 *
 */
function pointLookupClickRegister(e) {
    clickCount += 1;
    if (clickCount <= 1) {
        setTimeout(function() {
            if (clickCount <= 1) {
                pointLookup(e);
            }
            clickCount = 0;
        }, 400);
    }
}

function addLegendItem(name, red, green, blue, rgbhex, hiderangemax){
    var isoDateRegEx = /^(\d{4})-\d{2}-\d{2}T.*/; // e.g. 2001-02-31T12:00:00Z with year capture

    if (name.search(isoDateRegEx) > -1) {
        // convert full ISO date to YYYY-MM-DD format
        name = name.replace(isoDateRegEx, "$1");
    }
    var startOfRange = name.indexOf(":[");
    if (startOfRange != -1) {
        var nameVal = name.substring(startOfRange+1).replace("["," ").replace("]"," ").replace(" TO "," to ").trim();
        if (hiderangemax) nameVal = nameVal.split(' to ')[0];
    } else {
        var nameVal = name;
    }
    var legendText = (nameVal);

    $(".legendTable")
        .append($('<tr>')
            .append($('<td>')
                .append($('<i>')
                    .addClass('legendColour')
                    .attr('style', "background-color:" + (rgbhex!=''? "#" + rgbhex : "rgb("+ red +","+ green +","+ blue + ")") + ";")
                )
                .append($('<span>')
                    .addClass('legendItemName')
                    .html(legendText)
                )
            )
        );
}

function setMapTitle (MAP_CONF) {
    $('#occurrenceRecordCountAll').html("(" + MAP_CONF.pageResultsOccurrenceRecords.toLocaleString() + " in total)");
    $(".occurrenceRecordCount").html(MAP_CONF.pageResultsOccurrenceRecords.toLocaleString()); //species show charts tab
    if (MAP_CONF.presenceOrAbsence == 'presence') {
        $('#occurrenceRecordCount').html(MAP_CONF.pageResultsOccurrencePresenceRecords.toLocaleString() + " presence");
    } else if (MAP_CONF.presenceOrAbsence == 'absence') {
        $('#occurrenceRecordCount').html(MAP_CONF.pageResultsOccurrenceAbsenceRecords.toLocaleString() + " absence");
    } else { //all records
        $('#occurrenceRecordCount').html(MAP_CONF.pageResultsOccurrenceRecords.toLocaleString() + "");
        $('#occurrenceRecordCountAll').html("(" + MAP_CONF.allResultsOccurrenceRecordsNoMapFilter.toLocaleString() + " in total)");
    }
    if (MAP_CONF.mapType == 'search') {
        $('#speciesCount').html(Object.keys(speciesLayers._layers).length);
    }
}

var speciesLayers = new L.LayerGroup();

function fitMapToBounds(MAP_CONF) {
    var lat_min = null, lat_max = null, lon_min = null, lon_max = null;
    var mapContextUnencoded = $('<textarea />').html(MAP_CONF.mapQueryContext).text(); //to convert e.g. &quot; back to "

    for (i = 0; i < MAP_CONF.resultsToMapJSON.results.length; i++) {
        if (Number(MAP_CONF.resultsToMapJSON.results[i].occurrenceCount) > 0) {

            var jsonUrl = MAP_CONF.biocacheServiceUrl + "/mapping/bounds.json?q=lsid:" + MAP_CONF.resultsToMapJSON.results[i].guid + "&qc=" + mapContextUnencoded + (MAP_CONF.additionalMapFilter? '&' + MAP_CONF.additionalMapFilter : '');
            if (MAP_CONF.presenceOrAbsence == 'presence') {
                jsonUrl += "&fq=occurrence_status:present"
            } else if (MAP_CONF.presenceOrAbsence == 'absence') {
                jsonUrl += "&fq=-occurrence_status:present"
            }
            jsonUrl += "&callback=?";
            $.getJSON(jsonUrl, function(data) {
                var changed = false;
                if (data.length == 4 && data[0] != 0 && data[1] != 0) {
                    //console.log("data", data);

                    if (lat_min === null || lat_min > data[0]) { lat_min = data[0]; changed = true;}
                    if (lat_max === null || lat_max < data[2]) { lat_max = data[2]; changed = true;}
                    if (lon_min === null || lon_min > data[1]) { lon_min = data[1]; changed = true;}
                    if (lon_max === null || lon_max < data[3]) { lon_max = data[3]; changed = true;}
                }
                if (changed) {
                    var sw = L.latLng(lon_min || 0, lat_min || 0);
                    var ne = L.latLng(lon_max || 0, lat_max || 0);
                    //console.log("sw", sw.toString());
                    //console.log("ne", ne.toString());
                    var dataBounds = L.latLngBounds(sw, ne);
                    var mapBounds = MAP_CONF.map.getBounds();
                    MAP_CONF.map.fitBounds(dataBounds);
                    if (MAP_CONF.map.getZoom() > 12) {
                        MAP_CONF.map.setZoom(12);
                    }

                    MAP_CONF.map.invalidateSize(true);
                }
            });
        }
    }
}

function loadMap(MAP_CONF) {

    speciesLayers = new L.LayerGroup();

    var prms = {
        layers: 'ALA:occurrences',
        format: 'image/png',
        transparent: true,
        attribution: MAP_CONF.mapAttribution,
        bgcolor: "0x000000",
        outline: MAP_CONF.mapOutline
    };

    var mapContextUnencoded = $('<textarea/>').html(MAP_CONF.mapQueryContext).text(); //to convert e.g. &quot; back to "

    if (MAP_CONF.mapType == 'search') {
    //search results: multi-species map
        var taxonLayer = [];

        for (i = 0; i < MAP_CONF.resultsToMapJSON.results.length; i++) {
            if (Number(MAP_CONF.resultsToMapJSON.results[i].occurrenceCount) > 0) {
                prms["ENV"] = MAP_CONF.mapEnvOptions + ";color:" + colours[i];
                var url = MAP_CONF.biocacheServiceUrl + "/mapping/wms/reflect?q=lsid:" +
                    MAP_CONF.resultsToMapJSON.results[i].guid + "&qc=" + mapContextUnencoded + (MAP_CONF.additionalMapFilter? '&' + MAP_CONF.additionalMapFilter : '')
                if (MAP_CONF.presenceOrAbsence == 'presence') {
                    url += "&fq=occurrence_status:present"
                } else if (MAP_CONF.presenceOrAbsence == 'absence') {
                    url += "&fq=-occurrence_status:present"
                }
                taxonLayer[i] = L.tileLayer.wms(url, prms);
                taxonLayer[i].addTo(speciesLayers);
            }
        }
    } else if (MAP_CONF.mapType == 'show') {
    //single species map with possible criteria-based or colormode themeing
        if (MAP_CONF.mapLayersFqs != '') { // additional FQ criteria for each map layer
            fqsArr = MAP_CONF.mapLayersFqs.split("|");
            coloursArr = MAP_CONF.mapLayersColours.split("|");
            var prmsLayer = [];
            var taxonLayer = [];
            var htmlEntityDecoder = document.createElement('textarea');
            for (i = 0; i < fqsArr.length; i++) {
                prmsLayer[i] = $.extend({}, prms);
                prmsLayer[i]["ENV"] = MAP_CONF.mapEnvOptions + ";color:" + coloursArr[i];
                htmlEntityDecoder.innerHTML = fqsArr[i];
                var url = MAP_CONF.biocacheServiceUrl + "/mapping/wms/reflect?q=lsid:" +
                    MAP_CONF.guid + "&qc=" + mapContextUnencoded + (MAP_CONF.additionalMapFilter? '&' + MAP_CONF.additionalMapFilter : '') +
                    "&fq=" + htmlEntityDecoder.value;
                if (MAP_CONF.presenceOrAbsence == 'presence') {
                    url += "&fq=occurrence_status:present"
                } else if (MAP_CONF.presenceOrAbsence == 'absence') {
                    url += "&fq=-occurrence_status:present"
                }
                //console.log(url);
                taxonLayer[i] = L.tileLayer.wms(url, prmsLayer[i]);
                taxonLayer[i].addTo(speciesLayers);
            }
        } else {
            prms["ENV"] = MAP_CONF.mapEnvOptions;
            var url = MAP_CONF.biocacheServiceUrl + "/mapping/wms/reflect?q=lsid:" +
                MAP_CONF.guid + "&qc=" + mapContextUnencoded + (MAP_CONF.additionalMapFilter? '&' + MAP_CONF.additionalMapFilter : '');
            if (MAP_CONF.presenceOrAbsence == 'presence') {
                url += "&fq=occurrence_status:present"
            } else if (MAP_CONF.presenceOrAbsence == 'absence') {
                url += "&fq=-occurrence_status:present"
            }
            var taxonLayer = L.tileLayer.wms(url, prms);
            taxonLayer.addTo(speciesLayers);
        }
    }

    var ColourByControl = L.Control.extend({
        options: {
            position: 'topright',
            collapsed: false
        },
        onAdd: function (map) {
            // create the control container with a particular class name
            var $controlToAdd = $('.colourbyTemplate').clone();
            var container = L.DomUtil.create('div', 'leaflet-control-layers');
            var $container = $(container);
            $container.attr("id","colourByControl");
            $container.attr('aria-haspopup', true);
            $container.html($controlToAdd.html());
            return container;
        }
    });


    MAP_CONF.map = L.map('leafletMap', {
        center: [MAP_CONF.defaultDecimalLatitude, MAP_CONF.defaultDecimalLongitude],
        zoom: MAP_CONF.defaultZoomLevel,
        layers: [speciesLayers],
        scrollWheelZoom: false
    });

    var defaultBaseLayer = L.tileLayer(MAP_CONF.defaultMapUrl, {
        attribution: MAP_CONF.defaultMapAttr,
        subdomains: MAP_CONF.defaultMapDomain,
        mapid: MAP_CONF.defaultMapId,
        token: MAP_CONF.defaultMapToken
    });

    defaultBaseLayer.addTo(MAP_CONF.map);

    var baseLayers = {
        "Base layer": defaultBaseLayer
    };

    var overlays = {};

    if (MAP_CONF.mapType == 'search') {
        for (i = 0; i < MAP_CONF.resultsToMapJSON.results.length; i++) {
            if (Number(MAP_CONF.resultsToMapJSON.results[i].occurrenceCount) > 0) {
                overlays[MAP_CONF.resultsToMapJSON.results[i].scientificName] = taxonLayer[i];
            }
        }
        L.control.layers(baseLayers, overlays).addTo(MAP_CONF.map);
    } else if (MAP_CONF.mapType == 'show') {
        var sciName = MAP_CONF.scientificName;
        if (MAP_CONF.mapLayersFqs != '') { // additional FQ criteria for each map layer
            labelsArr = MAP_CONF.mapLayersLabels.split("|");
            for (i = 0; i < taxonLayer.length; i++) {
                overlays[sciName + ": " + labelsArr[i]] = taxonLayer[i];
            }
            L.control.layers(baseLayers, overlays).addTo(MAP_CONF.map);
        } else {
            overlays[sciName] = taxonLayer;
            L.control.layers(baseLayers, overlays).addTo(MAP_CONF.map);
        }
    }

    MAP_CONF.map.addControl(new ColourByControl());

    $('.colour-by-control').click(function(e){
        if($(this).parent().hasClass('leaflet-control-layers-expanded')){
            $(this).parent().removeClass('leaflet-control-layers-expanded');
            $('.colour-by-legend-toggle').show();
        } else {
            $(this).parent().addClass('leaflet-control-layers-expanded');
            $('.colour-by-legend-toggle').hide();
        }
        e.preventDefault();
        e.stopPropagation();
        return false;
    });

    $('.colour-by-control').parent().addClass('leaflet-control-layers-expanded');
    $('.colour-by-legend-toggle').hide();

    $('#colourByControl').mouseover(function(e){
        //console.log('mouseover');
        MAP_CONF.map.dragging.disable();
        MAP_CONF.map.off('click', pointLookupClickRegister);
    });

    $('#colourByControl').mouseout(function(e){
        //console.log('mouseout');
        MAP_CONF.map.dragging.enable();
        MAP_CONF.map.on('click', pointLookupClickRegister);
    });

    $('.hideColourControl').click(function(e){
        //console.log('hideColourControl');
        $('#colourByControl').removeClass('leaflet-control-layers-expanded');
        $('.colour-by-legend-toggle').show();
        e.preventDefault();
        e.stopPropagation();
        return false;
    });

    MAP_CONF.map.invalidateSize(false);


    fitMapToBounds(MAP_CONF);

    if (MAP_CONF.mapType == 'search') {
        $('.legendTable').html('');
        $('.legendTable')
            .append($('<tr>')
                .append($('<td>')
                    .addClass('legendTitle')
                    .html("Species" + ":")
                )
            );


        for (i = 0; i < MAP_CONF.resultsToMapJSON.results.length; i++) {
            if (Number(MAP_CONF.resultsToMapJSON.results[i].occurrenceCount) > 0) {
                addLegendItem(MAP_CONF.resultsToMapJSON.results[i].scientificName, 0, 0, 0, colours[i], false);
            }
        }
    } else if (MAP_CONF.mapType == 'show') {

        if( MAP_CONF.mapEnvOptions.indexOf("colormode:") >= 0 || MAP_CONF.mapLayersLabels != '') {
            var mapOptArr = MAP_CONF.mapEnvOptions.split(";");
            var legendQ = '';
            for (var i = 0; i < mapOptArr.length; i++) {
                if (mapOptArr[i].indexOf('colormode:') == 0) {
                    legendQ = mapOptArr[i].substring('colormode:'.length);
                    break;
                }
            }
            $('.legendTable').html('');
            $(".legendTable")
                .append($('<tr>')
                    .append($('<td>')
                        .addClass('legendTitle')
                        .html(MAP_CONF.mapEnvLegendTitle + ":")
                    )
                );

            if (legendQ != '') {
                var legendUrl = MAP_CONF.biocacheUrl + "/occurrence/legend?q=lsid:" + MAP_CONF.guid + "&cm=" + legendQ + "&type=application/json";
                //console.log(legendUrl);
                $.ajax({
                    url: legendUrl,
                    success: function (data) {

                        $.each(data, function (index, legendDef) {
                            var legItemName = legendDef.name ? legendDef.name : 'Not specified';
                            addLegendItem(legItemName, legendDef.red, legendDef.green, legendDef.blue, '', MAP_CONF.mapEnvLegendHideMax);
                        });
                    }
                });
            } else if (MAP_CONF.mapLayersLabels != '') {
                //use predefined legend entries and colours
                var mapLabelsArr = MAP_CONF.mapLayersLabels.split("|");
                var mapColoursArr = MAP_CONF.mapLayersColours.split("|");
                for (var i = 0; i < mapLabelsArr.length; i++) {
                    addLegendItem(mapLabelsArr[i], 0, 0, 0, mapColoursArr[i], false); //use rgbhex and full label provided
                }
            } else {
                $('#colourByControl').hide();
            }
        }
    }
}
