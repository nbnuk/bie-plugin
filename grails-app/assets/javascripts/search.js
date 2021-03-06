//= require jquery.sortElemets
//= require jquery-ui.min.js
/*
 * Copyright (C) 2012 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *//**
 * Created with IntelliJ IDEA.
 * User: nick
 * Date: 29/06/12
 * Time: 11:17 AM
 * To change this template use File | Settings | File Templates.
 */
$(document).ready(function() {
    // set the search input to the current q param value
    var query = SEARCH_CONF.query;
    if (query) {
        $(":input#search-2011").val(query);
    }

    // listeners for sort widgets
    $("select#sort-by").change(function() {
        var val = $("option:selected", this).val();
        reloadWithParam('sortField',val);
    });
    $("select#sort-order").change(function() {
        var val = $("option:selected", this).val();
        reloadWithParam('dir',val);
    });
    $("select#per-page").change(function() {
        var val = $("option:selected", this).val();
        reloadWithParam('rows',val);
    });

    // AJAX search results
    if (SEARCH_CONF.isNBNinns) {
        injectBiocacheResultsActual(MAP_CONF.allResultsOccurrenceRecords, SEARCH_CONF.maxSpecies);
        $('#related-searches').removeClass('hide');
    } else {
        if (!(SEARCH_CONF.isNBNni && SEARCH_CONF.isCompactLayout)) {
            injectBhlResults();
            injectBiocacheResults();
        }
    }

    // in mobile view toggle display of facets
    $("#toggleFacetDisplay").click(function() {
        $(this).find("i").toggleClass("icon-chevron-down icon-chevron-right");
        if ($("#accordion").is(":visible")) {
            $("#accordion").removeClass("overrideHide");
        } else {
            $("#accordion").addClass("overrideHide");
        }
    });
});



/**
 * Tag results on page with configured list membership with HTML decoration
 *
 * @param lsidsOnPage
 */

function tagResults(lsidsOnPage) {

    if (SHOW_CONF.tagIfInLists) {
        var unencodedTIIL = $('<textarea />').html(SHOW_CONF.tagIfInLists).text();
        var tagIfInLists = JSON.parse(unencodedTIIL);
        for(var lst = 0; lst < tagIfInLists.length; lst++) {
            var lstId = tagIfInLists[lst].specieslist;
            var lstItem = tagIfInLists[lst];
            $.getJSON(SHOW_CONF.speciesListUrl + '/ws/speciesListItems/' + lstId, tagResultsMakeCallback(lsidsOnPage, lstItem));
        }
    }
}

function tagResultsMakeCallback(lsidsOnPage, lstItem) {
    return function (data) {
        for (var i = 0; i < data.length; i++) {
            var spp = data[i];
            var lsid = spp.lsid;
            if ($.inArray(lsid, lsidsOnPage) > -1) {
                var linkTag = "species/" + lsid;
                var addTagsTo = $('h3 a[href$="' + linkTag + '"]');
                $(lstItem.tag).insertAfter(addTagsTo);
            }
        }
    };
}


/**
 * Build URL params to remove selected fq
 *
 * @param facet
 */
function removeFacet(facetIdx) {

    var q = $.getQueryParam('q') ? $.getQueryParam('q') : SEARCH_CONF.query ; //$.query.get('q')[0];
    var fqList = $.getQueryParam('fq'); //$.query.get('fq');

    console.log('Remove facet.,...');
    console.log(facetIdx);
    console.log(fqList);

    var paramList = [];

    if (q != null) {
        paramList.push("q=" + q);
    }

    fqList.splice(facetIdx,1);

    if (fqList != null && fqList.length > 0) {
        paramList.push("fq=" + fqList.join("&fq="));
        //alert("pushing fq back on: "+fqList);
    } else {
        // empty fq so redirect doesn't happen
        paramList.push("fq=");
    }
    console.log("new URL: " + window.location.pathname + '?' + paramList.join('&'));
    window.location.href = window.location.pathname + '?' + paramList.join('&');
}

/**
 * Catch sort drop-down and build GET URL manually
 */
function reloadWithParam(paramName, paramValue) {
    var paramList = [];
    var q = $.getQueryParam('q') ? $.getQueryParam('q') : SEARCH_CONF.query ;
    var fqList = $.getQueryParam('fq'); //$.query.get('fq');
    var sort = $.getQueryParam('sortField');
    if (sort == null || sort === undefined) {
        sort = $('#sort-by').find(":selected").val();
    }
    var dir = $.getQueryParam('dir');
    if (dir == null || dir === undefined) {
        dir = $('#sort-order').find(":selected").val();
    }
    var rows = $.getQueryParam('rows');
    if (rows == null || rows === undefined) {
        rows = $('#per-page').find(":selected").val();
    }
    var includeRecordsFilter = $.getQueryParam('includeRecordsFilter');
    // add query param
    if (q != null) {
        paramList.push("q=" + q);
    }
    // add filter query param
    if (fqList != null) {
        paramList.push("fq=" + fqList.join("&fq="));
    }
    // add sort param if already set
    if (paramName != 'sortField' && (sort != null && sort !== undefined)) {
        paramList.push('sortField' + "=" + sort);
    }
    // add dir param if already set
    if (paramName != 'dir' && dir != null) {
        paramList.push('dir' + "=" + dir);
    }
    // add rows param if already set
    if (paramName != 'rows' && rows != null) {
        paramList.push('rows' + "=" + rows);
    }
    if (includeRecordsFilter) {
        paramList.push('includeRecordsFilter' + '=' + includeRecordsFilter);
    }
    // add the changed value
    if (paramName != null && paramValue != null) {
        paramList.push(paramName + "=" +paramValue);
    }
    //alert("paramName = " + paramName + " and paramValue = " + paramValue);
    //alert("params = "+paramList.join("&"));
    window.location.href = window.location.pathname + '?' + paramList.join('&');
}

// jQuery getQueryParam Plugin 1.0.0 (20100429)
// By John Terenzio | http://plugins.jquery.com/project/getqueryparam | MIT License
// Adapted by Nick dos Remedios to handle multiple params with same name - return a list
(function ($) {
    // jQuery method, this will work like PHP's $_GET[]
    $.getQueryParam = function (param) {
        // get the pairs of params fist
        var pairs = location.search.substring(1).split('&');
        var values = [];
        // now iterate each pair
        for (var i = 0; i < pairs.length; i++) {
            var params = pairs[i].split('=');
            if (params[0] == param) {
                // if the param doesn't have a value, like ?photos&videos, then return an empty srting
                //return params[1] || '';
                values.push(params[1]);
            }
        }

        if (values.length > 0) {
            return values;
        } else {
            //otherwise return undefined to signify that the param does not exist
            return undefined;
        }

    };
})(jQuery);

function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function injectBhlResults() {

    var bhlHtml = "<li><a href='http://www.biodiversitylibrary.org/search?SearchTerm=" + SEARCH_CONF.query + "&SearchCat=M#/names' target='bhl'>BHL Literature </a></li>"
    insertSearchLinks(bhlHtml);
}

function injectBiocacheResults() {
    var queryToUse = (SEARCH_CONF.query == "" || SEARCH_CONF.query == "*" ? "*:*" : SEARCH_CONF.query);
    if (queryToUse != "*:*") return; //new search cannot use this simple model for getting occurrence records
    var biocacheContextUnencoded = $('<textarea />').html(SEARCH_CONF.biocacheQueryContext).text(); //to convert e.g. &quot; back to "
    var url = SEARCH_CONF.biocacheServicesUrl + "/occurrences/search.json?q=" + queryToUse + "&start=0&pageSize=0&facet=off&qc=" + biocacheContextUnencoded;
    console.log("url_biocache: " + url);
    $.ajax({
        url: url,
        dataType: 'jsonp',
        success:  function(data) {
            var maxItems = parseInt(data.totalRecords, 10);
            var url = SEARCH_CONF.biocacheUrl + "/occurrences/search?q=" + queryToUse;
            var html = "<li data-count=\"" + maxItems + "\"><a href=\"" + url + "\" id=\"biocacheSearchLink\">Occurrence records</a> (" + numberWithCommas(maxItems) + ")</li>";
            insertSearchLinks(html);
        }
    });
}

function injectBiocacheSearch(lsids, recsTot) {
    var biocacheContextUnencoded = $('<textarea />').html(SEARCH_CONF.biocacheQueryContext).text(); //to convert e.g. &quot; back to "
    var url = SEARCH_CONF.biocacheUrl + "/occurrences/search?q=lsid:(" + lsids + ")&qc=" + biocacheContextUnencoded;
    var html = "<li data-count=\"" + recsTot + "\"><a href=\"" + url + "\" id=\"biocacheSearchLink\">Occurrence records</a> (" + numberWithCommas(recsTot) + ")</li>";
    insertSearchLinks(html);
}

function injectBiocacheResultsActual(recsTot, limitSpp) {
    var q = $.getQueryParam('q') ? $.getQueryParam('q') : SEARCH_CONF.query ;
    var fqList = $.getQueryParam('fq');
    var url = SEARCH_CONF.bieUrl + "/occurrences?q=" + q + (fqList? "&fq=" + fqList.join("&fq=") : "") + "&fq=" + SEARCH_CONF.recordsFilter;
    var html = "<span class='biocacheRecordsLink'><a href=\"" + url + "\" id=\"biocacheRecordsLink\" title='View occurrences for up to " + limitSpp + " species'>View occurrence records</a> (" + numberWithCommas(recsTot) + ")</span>";
    $(".record-cursor-details").append(html);
}

function insertSearchLinks(html) {
    // add content
    $("#related-searches ul").append(html);
    // sort by count
    $('#related-searches ul li').sortElements(function(a, b){
        return $(a).data("count") < $(b).data("count") ? 1 : -1;
    });
    $('#related-searches').removeClass('hide');
}

//= require leaflet.js

