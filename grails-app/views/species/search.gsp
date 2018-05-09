%{--
  - Copyright (C) 2012 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
  --}%
<%@ page import="au.org.ala.bie.BieTagLib" contentType="text/html;charset=UTF-8" %>
<g:set var="alaUrl" value="${grailsApplication.config.ala.baseURL}"/>
<g:set var="biocacheUrl" value="${grailsApplication.config.biocache.baseURL}"/>
<!doctype html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <title>${query} | Search | ${raw(grailsApplication.config.skin.orgNameLong)}</title>
    <meta name="breadcrumb" content="Search results"/>
    <asset:javascript src="search"/>
    <asset:javascript src="atlas"/>
    <asset:stylesheet src="atlas"/>
    <asset:stylesheet src="search"/>
    <asset:script type="text/javascript">
        // global var to pass GSP vars into JS file
        SEARCH_CONF = {
            searchResultTotal: ${searchResults.totalRecords},
            query: "${BieTagLib.escapeJS(query)}",
            serverName: "${grailsApplication.config.grails.serverURL}",
            bieUrl: "${grailsApplication.config.bie.baseURL}",
            biocacheUrl: "${grailsApplication.config.biocache.baseURL}",
            biocacheServicesUrl: "${grailsApplication.config.biocacheService.baseURL}",
            bhlUrl: "${grailsApplication.config.bhl.baseURL}",
            biocacheQueryContext: "${grailsApplication.config.biocacheService.queryContext}",
            geocodeLookupQuerySuffix: "${grailsApplication.config.geocode.querySuffix}"
        }
    </asset:script>
</head>
<body class="general-search page-search">

<section class="container">

    <header class="pg-header">
        <div class="row">
            <div class="col-sm-9">
                <h1>
                    Search for <strong>${searchResults.queryTitle == "*:*" ? 'everything' : searchResults.queryTitle}</strong>
                    returned <g:formatNumber number="${searchResults.totalRecords}" type="number"/>
                    ${params.startIndex} , ${params.rows}
                 </h1>
            </div>
            <div class="col-sm-3">
                <div id="related-searches" class="related-searches hide">
                    <h4>Related Searches</h4>
                    <ul class="list-unstyled"></ul>
                </div>
            </div>
        </div>
    </header>

    <div class="main-content panel panel-body">
        <g:if test="${searchResults.totalRecords}">
        <g:set var="paramsValues" value="${[:]}"/>
        <div class="row">
            <div class="col-sm-3">
                <div class="well refine-box">
                    <h2 class="hidden-xs">Refine results</h2>
                    <h2 class="visible-xs"><a href="#refine-options" data-toggle="collapse"><span class="glyphicon glyphicon-chevron-down" aria-hidden="true"></span> Refine results</a>
                    </h2>

                    <div id="refine-options" class="collapse mobile-collapse">
                        <g:if test="${query && filterQuery}">
                            <g:set var="queryParam">q=${query.encodeAsHTML()}<g:if test="${!filterQuery.isEmpty()}">&fq=${filterQuery?.join("&fq=")}</g:if></g:set>
                        </g:if>
                        <g:else>
                            <g:set var="queryParam">q=${query.encodeAsHTML()}<g:if test="${params.fq}">&fq=${fqList?.join("&fq=")}</g:if></g:set>
                        </g:else>
                        <g:if test="${facetMap}">
                                <div class="current-filters" id="currentFilters">
                                    <h3>Current filters</h3>
                                    <ul class="list-unstyled">
                                        <g:each var="item" in="${facetMap}" status="facetIdx">
                                            <li>
                                                <g:if test="${item.key?.contains("uid")}">
                                                    <g:set var="resourceType">${item.value}_resourceType</g:set>
                                                    ${collectionsMap?.get(resourceType)}: <strong>&nbsp;${collectionsMap?.get(item.value)}</strong>
                                                </g:if>
                                                <g:else>
                                                    <g:message code="facet.${item.key}" default="${item.key}"/>: <strong><g:message code="${item.key}.${item.value}" default="${item.value}"/></strong>
                                                </g:else>
                                                <a href="#" onClick="javascript:removeFacet(${facetIdx}); return true;" title="remove filter"><span class="glyphicon glyphicon-remove-sign"></span></a>
                                            </li>
                                        </g:each>
                                    </ul>
                                </div>
                        </g:if>

                        <!-- facets -->
                        <g:each var="facetResult" in="${searchResults.facetResults}">
                            <g:if test="${!facetMap?.get(facetResult.fieldName) && !filterQuery?.contains(facetResult.fieldResult?.opt(0)?.label) && !facetResult.fieldName?.contains('idxtype1') && facetResult.fieldResult.length() > 0 }">

                                <div class="refine-list" id="facet-${facetResult.fieldName}">
                                <h3><g:message code="facet.${facetResult.fieldName}" default="${facetResult.fieldName}"/></h3>
                                <ul class="list-unstyled">
                                    <g:set var="lastElement" value="${facetResult.fieldResult?.get(facetResult.fieldResult.length()-1)}"/>
                                    <g:if test="${lastElement.label == 'before'}">
                                        <li><g:set var="firstYear" value="${facetResult.fieldResult?.opt(0)?.label.substring(0, 4)}"/>
                                            <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[* TO ${facetResult.fieldResult.opt(0)?.label}]">Before ${firstYear}</a>
                                            (<g:formatNumber number="${lastElement.count}" type="number"/>)
                                        </li>
                                    </g:if>
                                    <g:each var="fieldResult" in="${facetResult.fieldResult}" status="vs">
                                        <g:if test="${vs == 5}">
                                            </ul>
                                            <ul class="collapse list-unstyled">
                                        </g:if>
                                        <g:set var="dateRangeTo"><g:if test="${vs == lastElement}">*</g:if><g:else>${facetResult.fieldResult[vs+1]?.label}</g:else></g:set>
                                        <g:if test="${facetResult.fieldName?.contains("occurrence_date") && fieldResult.label?.endsWith("Z")}">
                                            <li><g:set var="startYear" value="${fieldResult.label?.substring(0, 4)}"/>
                                                <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[${fieldResult.label} TO ${dateRangeTo}]">${startYear} - ${startYear + 10}</a>
                                                (<g:formatNumber number="${fieldResult.count}" type="number"/>)</li>
                                        </g:if>
                                        <g:elseif test="${fieldResult.label?.endsWith("before")}"><%-- skip --%></g:elseif>
                                        <g:elseif test="${fieldResult.label?.isEmpty()}">
                                        </g:elseif>
                                        <g:else>
                                            <li><a href="?${request.queryString}&fq=${facetResult.fieldName}:%22${fieldResult.label}%22">
                                                <g:message code="${facetResult.fieldName}.${fieldResult.label}" default="${fieldResult.label?:"[unknown]"}"/>
                                            </a>
                                                (<g:formatNumber number="${fieldResult.count}" type="number"/>)
                                            </li>
                                        </g:else>
                                    </g:each>
                                </ul>
                                <g:if test="${facetResult.fieldResult.size() > 5}">
                                    <a class="expand-options" href="javascript:void(0)">
                                        More
                                    </a>
                                </g:if>
                                </div>
                            </g:if>
                        </g:each>
                    </div><!-- refine-options -->
                </div><!-- refine-box -->
            </div>

            <div class="col-sm-9">

                <div class="result-options">

                    <g:if test="${idxTypes.contains("TAXON")}">
                        <div class="download-button pull-right">
                            <g:set var="downloadUrl" value="${grailsApplication.config.bie.index.url}/download?${request.queryString?:''}${grailsApplication.config.bieService.queryContext}"/>
                            <a class="btn btn-default active btn-small" href="${downloadUrl}" title="Download a list of taxa for your search">
                                <i class="glyphicon glyphicon-download"></i>
                                Download
                            </a>
                        </div>
                    </g:if>

                    <g:if test="${grailsApplication.config?.search?.mapResults=='true'}">
                        <div class="taxon-map">
                            <h3><span class="occurrenceRecordCount">0</span> presence records <span class="occurrenceRecordCountAll"></span></h3>
                            <g:if test="${message(code:'overview.map.button.records.map.subtitle', default:'')}">
                                <p>${g.message(code:'overview.map.button.records.map.subtitle')}</p>
                            </g:if>
                            <div id="leafletMap"></div>
                            <!-- RR for legend display, if needed -->
                            <div id="template" style="display:none">
                                <div class="colourbyTemplate">
                                    <a class="colour-by-legend-toggle colour-by-control tooltips" href="#" title="Map legend - click to expand"><i class="fa fa-list-ul fa-lg" style="color:#333"></i></a>
                                    <form class="leaflet-control-layers-list">
                                        <div class="leaflet-control-layers-overlays">
                                            <div style="overflow:auto;max-height:400px;">
                                                <a href="#" class="hideColourControl pull-right" style="padding-left:10px;"><i class="glyphicon glyphicon-remove" style="color:#333"></i></a>
                                                <table class="legendTable"></table>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>

                        <g:if test="${grailsApplication.config.spatial.baseURL}">
                            <g:set var="mapUrl">${grailsApplication.config.spatial.baseURL}?q=lsid:(${lsids})</g:set>
                        </g:if>
                        <g:else>
                            <g:set var="mapUrl">${biocacheUrl}/occurrences/search?q=lsid:(${lsids})#tab_mapView</g:set>
                        </g:else>
                    </g:if>

                    <form class="form-inline">
                        <div class="form-group">
                            <label for="per-page">Results per page</label>
                            <select class="form-control input-sm" id="per-page" name="per-page">
                                <option value="10" ${(params.rows == '10') ? "selected=\"selected\"" : ""}>10</option>
                                <option value="20" ${(params.rows == '20') ? "selected=\"selected\"" : ""}>20</option>
                                <option value="50" ${(params.rows == '50') ? "selected=\"selected\"" : ""}>50</option>
                                <option value="100" ${(params.rows == '100') ? "selected=\"selected\"" : ""} >100</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="sort-by">Sort by</label>
                            <select class="form-control input-sm" id="sort-by" name="sort-by">
                                <option value="score" ${(params.sortField == 'score') ? "selected=\"selected\"" : ""}>best match</option>
                                <option value="scientificName" ${(params.sortField == 'scientificName') ? "selected=\"selected\"" : ""}>scientific name</option>
                                <option value="commonNameSingle" ${(params.sortField == 'commonNameSingle') ? "selected=\"selected\"" : ""}>common name</option>
                                <option value="rank" ${(params.sortField == 'rank') ? "selected=\"selected\"" : ""}>taxon rank</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="sort-order">Sort order</label>
                            <select class="form-control input-sm" id="sort-order" name="sort-order">
                                <option value="asc" ${(params.dir == 'asc') ? "selected=\"selected\"" : ""}>ascending</option>
                                <option value="desc" ${(params.dir == 'desc' || !params.dir) ? "selected=\"selected\"" : ""}>descending</option>
                            </select>
                        </div>
                    </form>

                </div><!-- result-options -->

                <input type="hidden" value="${pageTitle}" name="title"/>
                <ol id="search-results-list" class="search-results-list list-unstyled">

                    <g:each var="result" in="${searchResults.results}">
                        <li class="search-result clearfix">

                        <g:set var="sectionText"><g:if test="${!facetMap.idxtype}"><span><b>Section:</b> <g:message code="idxType.${result.idxType}"/></span></g:if></g:set>
                            <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">

                                <g:set var="taxonPageLink">${request.contextPath}/species/${result.linkIdentifier ?: result.guid}</g:set>
                                <g:set var="acceptedPageLink">${request.contextPath}/species/${result.acceptedConceptID ?: result.linkIdentifier ?: result.guid}</g:set>
                                <g:if test="${result.image}">
                                    <div class="result-thumbnail">
                                        <a href="${acceptedPageLink}">
                                            <img src="${grailsApplication.config.image.thumbnailUrl}${result.image}" alt="">
                                        </a>
                                    </div>
                                </g:if>

                                <h3>${result.rank}:
                                    <a href="${acceptedPageLink}"><bie:formatSciName rankId="${result.rankID}" taxonomicStatus="${result.taxonomicStatus}" nameFormatted="${result.nameFormatted}" nameComplete="${result.nameComplete}" name="${result.name}" acceptedName="${result.acceptedConceptName}"/></a><%--
                                    --%><g:if test="${result.commonNameSingle}"><span class="commonNameSummary">&nbsp;&ndash;&nbsp;${result.commonNameSingle}</span></g:if>
                                </h3>

                                <g:if test="${result.commonName != result.commonNameSingle}"><p class="alt-names">${result.commonName}</p></g:if>
                                <g:if test="${taxonPageLink != acceptedPageLink}"><p class="alt-names"</g:if>
                                <g:each var="fieldToDisplay" in="${grailsApplication.config.additionalResultsFields.split(",")}">
                                    <g:if test='${result."${fieldToDisplay}"}'>
                                        <p class="summary-info"><strong><g:message code="${fieldToDisplay}" default="${fieldToDisplay}"/>:</strong> ${result."${fieldToDisplay}"}</p>
                                    </g:if>
                                </g:each>
                            </g:if>
                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'COMMON'}">
                                <g:set var="speciesPageLink">${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}</g:set>
                                <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                    <a href="${speciesPageLink}">${result.name}</a></h4>
                            </g:elseif>
                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'IDENTIFIER'}">
                                <g:set var="speciesPageLink">${request.contextPath}/species/${result.linkIdentifier?:result.taxonGuid}</g:set>
                                <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                    <a href="${speciesPageLink}">${result.guid}</a></h4>
                            </g:elseif>
                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'REGION'}">
                                <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                    <a href="${grailsApplication.config.regions.baseURL}/feature/${result.guid}">${result.name}</a></h4>
                                <p>
                                    <span>${result?.description &&  result?.description != result?.name ?  result?.description : ""}</span>
                                </p>
                            </g:elseif>
                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'LOCALITY'}">
                                <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                    <bie:constructEYALink result="${result}">
                                        ${result.name}
                                    </bie:constructEYALink>
                                </h4>
                                <p>
                                    <span>${result?.description?:""}</span>
                                </p>
                            </g:elseif>
                            <g:elseif test="${result.has("idxtype") && result.idxtype == 'LAYER'}">
                                <h4><g:message code="idxtype.${result.idxtype}"/>:
                                    <a href="${grailsApplication.config.spatial.baseURL}?layers=${result.guid}">${result.name}</a></h4>
                                <p>
                                    <g:if test="${result.dataProviderName}"><strong>Source: ${result.dataProviderName}</strong></g:if>
                                </p>
                            </g:elseif>
                            <g:elseif test="${result.has("name")}">
                                <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                    <a href="${result.guid}">${result.name}</a></h4>
                                <p>
                                    <span>${result?.description?:""}</span>
                                </p>
                            </g:elseif>
                            <g:elseif test="${result.has("acronym") && result.get("acronym")}">
                                <h4><g:message code="idxtype.${result.idxtype}"/>:
                                    <a href="${result.guid}">${result.name}</a></h4>
                                <p>
                                    <span>${result.acronym}</span>
                                </p>
                            </g:elseif>
                            <g:elseif test="${result.has("description") && result.get("description")}">
                                <h4><g:message code="idxtype.${result.idxtype}"/>:
                                    <a href="${result.guid}">${result.name}</a></h4>
                                <p>
                                    <span class="searchDescription">${result.description?.trimLength(500)}</span>
                                </p>
                            </g:elseif>
                            <g:elseif test="${result.has("highlight") && result.get("highlight")}">
                                <h4><g:message code="idxtype.${result.idxtype}"/>:
                                    <a href="${result.guid}">${result.name}</a></h4>
                                <p>
                                    <span>${result.highlight}</span>
                                </p>
                            </g:elseif>
                            <g:else>
                                <h4><g:message code="idxtype.${result.idxtype}"/> TEST: <a href="${result.guid}">${result.name}</a></h4>
                            </g:else>
                            <g:if test="${result.has("highlight")}">
                                <p><bie:displaySearchHighlights highlight="${result.highlight}"/></p>
                            </g:if>
                            <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                <ul class="summary-actions list-inline">
                                    <g:if test="${result.rankID < 7000}">
                                        <li><g:link controller="species" action="imageSearch" params="[id:result.guid]">View images of species within this ${result.rank}</g:link></li>
                                    </g:if>

                                    <g:if test="${grailsApplication.config.sightings.guidUrl}">
                                        <li><a href="${grailsApplication.config.sightings.guidUrl}${result.guid}">Record a sighting/share a photo</a></li>
                                    </g:if>
                                    <g:if test="${grailsApplication.config.occurrenceCounts.enabled.toBoolean() && result?.occurrenceCount?:0 > 0}">
                                        <li>
                                        <a href="${biocacheUrl}/occurrences/search?q=lsid:${result.guid}">Occurrences:
                                        <g:formatNumber number="${result.occurrenceCount}" type="number"/></a></span>
                                        </li>
                                    </g:if>
                                    <g:if test="${result.acceptedConceptID && result.acceptedConceptID != result.guid}">
                                        <li><g:link controller="species" action="show" params="[guid:result.guid]"><g:message code="taxonomicStatus.${result.taxonomicStatus}" default="${result.taxonomicStatus}"/></g:link></li
                                    </g:if>
                                </ul>
                            </g:if>
                        </li>
                    </g:each>
                </ol><!--close results-->

                <div>
                    <tb:paginate total="${searchResults?.totalRecords}" max="${params.rows}"
                            action="search"
                            params="${[q: params.q, fq: params.fq, dir: params.dir, sortField: params.sortField, rows: params.rows]}"
                    />
                </div>
            </div><!--end .col-wide last-->
        </div><!--end .inner-->
    </g:if>

    </div>
</section>

<div id="result-template" class="row hide">
    <div class="col-sm-12">
        <ol class="search-results-list list-unstyled">
            <li class="search-result clearfix">
                <h4><g:message code="idxtype.LOCALITY"/> : <a class="exploreYourAreaLink" href="">Address here</a></h4>
            </li>
        </ol>
    </div>
</div>

<g:if test="${searchResults.totalRecords == 0}">
    <asset:script type="text/javascript" >
        $(function(){
            console.log(SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix);
            $.get( SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query  + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix, function( searchResults ) {
                for(var i=0; i< searchResults.length; i++){
                    var $results = $('#result-template').clone(true);
                    $results.attr('id', 'results-lists');
                    $results.removeClass('hide');
                    console.log(searchResults)
                    if(searchResults.length > 0){
                        $results.find('.exploreYourAreaLink').html(searchResults[i].name);
                        $results.find('.exploreYourAreaLink').attr('href', '${grailsApplication.config.biocache.baseURL}/explore/your-area#' +
                                searchResults[0].latitude  +
                                '|' +  searchResults[0].longitude +
                                '|12|ALL_SPECIES'
                        );
                        $('.main-content').append($results.html());
                    }
                }
            });
        });
    </asset:script>
</g:if>
<asset:script type="text/javascript" >

var SHOW_CONF = {
        biocacheUrl:        "${grailsApplication.config.biocache.baseURL}",
        biocacheServiceUrl: "${grailsApplication.config.biocacheService.baseURL}",
        layersServiceUrl:   "${grailsApplication.config.layersService.baseURL}",
        collectoryUrl:      "${grailsApplication.config.collectory.baseURL}",
        profileServiceUrl:  "${grailsApplication.config.profileService.baseURL}",
        serverName:         "${grailsApplication.config.grails.serverURL}",
        bieUrl:             "${grailsApplication.config.bie.baseURL}",
        alertsUrl:          "${grailsApplication.config.alerts.baseUrl}",
        remoteUser:         "${request.remoteUser ?: ''}",
        defaultDecimalLatitude: ${grailsApplication.config.defaultDecimalLatitude},
        defaultDecimalLongitude: ${grailsApplication.config.defaultDecimalLongitude},
        defaultZoomLevel: ${grailsApplication.config.defaultZoomLevel},
        mapAttribution: "${raw(grailsApplication.config.skin.orgNameLong)}",
        defaultMapUrl: "${grailsApplication.config.map.default.url}",
        defaultMapAttr: "${raw(grailsApplication.config.map.default.attr)}",
        defaultMapDomain: "${grailsApplication.config.map.default.domain}",
        defaultMapId: "${grailsApplication.config.map.default.id}",
        defaultMapToken: "${grailsApplication.config.map.default.token}",
        recordsMapColour: "${grailsApplication.config.map.records.colour}",
        mapQueryContext: "${grailsApplication.config.biocacheService.queryContext}",
        additionalMapFilter: "${raw(grailsApplication.config.additionalMapFilter)}",
        noImage100Url: "${resource(dir: 'images', file: 'noImage100.jpg')}",
        map: null,
        imageDialog: '${imageViewerType}',
        addPreferenceButton: ${imageClient.checkAllowableEditRole()},
        mapOutline: ${grailsApplication.config.map.outline ?: 'false'},
        mapEnvOptions: "name:circle;size:4;opacity:0.8",
        mapLayersFqs: "${grailsApplication.config.searchmap?.layers?.fqs?:''}",
        speciesAdditionalHeadlines: "${grailsApplication.config.species?.additionalHeadlines?:''}"
};

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

function loadMap() {

    var prms = {
        layers: 'ALA:occurrences',
        format: 'image/png',
        transparent: true,
        attribution: SHOW_CONF.mapAttribution,
        bgcolor: "0x000000",
        outline: SHOW_CONF.mapOutline
    };

    var speciesLayers = new L.LayerGroup();

    var mapContextUnencoded = $('<textarea />').html(SHOW_CONF.mapQueryContext).text(); //to convert e.g. &quot; back to "


    var taxonLayer = [];
    var occurrenceCount = 0;
    <g:each status="i" var="result" in="${searchResults.results}">
        if (${result.occurrenceCount} > 0) {
            prms["ENV"] = SHOW_CONF.mapEnvOptions + ";color:" + colours[${i}];
            taxonLayer[${i}] = L.tileLayer.wms(SHOW_CONF.biocacheServiceUrl + "/mapping/wms/reflect?q=lsid:" +
                "${result.guid}" + "&qc=" + mapContextUnencoded + SHOW_CONF.additionalMapFilter, prms);
            taxonLayer[${i}].addTo(speciesLayers);
            occurrenceCount += ${result.occurrenceCount};
        }
    </g:each>

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


    SHOW_CONF.map = L.map('leafletMap', {
        center: [SHOW_CONF.defaultDecimalLatitude, SHOW_CONF.defaultDecimalLongitude],
        zoom: SHOW_CONF.defaultZoomLevel,
        layers: [speciesLayers],
        scrollWheelZoom: false
    });

    var defaultBaseLayer = L.tileLayer(SHOW_CONF.defaultMapUrl, {
        attribution: SHOW_CONF.defaultMapAttr,
        subdomains: SHOW_CONF.defaultMapDomain,
        mapid: SHOW_CONF.defaultMapId,
        token: SHOW_CONF.defaultMapToken
    });

    defaultBaseLayer.addTo(SHOW_CONF.map);

    var baseLayers = {
        "Base layer": defaultBaseLayer
    };

    var overlays = {};
    <g:each status="i" var="result" in="${searchResults.results}">
        if (${result.occurrenceCount} > 0) {
            overlays["${result.scientificName}"] = taxonLayer[${i}];
        }
    </g:each>
    L.control.layers(baseLayers, overlays).addTo(SHOW_CONF.map);

    SHOW_CONF.map.addControl(new ColourByControl());

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
        SHOW_CONF.map.dragging.disable();
        SHOW_CONF.map.off('click', pointLookupClickRegister);
    });

    $('#colourByControl').mouseout(function(e){
        //console.log('mouseout');
        SHOW_CONF.map.dragging.enable();
        SHOW_CONF.map.on('click', pointLookupClickRegister);
    });

    $('.hideColourControl').click(function(e){
        //console.log('hideColourControl');
        $('#colourByControl').removeClass('leaflet-control-layers-expanded');
        $('.colour-by-legend-toggle').show();
        e.preventDefault();
        e.stopPropagation();
        return false;
    });

    //SHOW_CONF.map.on('click', onMapClick);
    SHOW_CONF.map.invalidateSize(false);

    $('.occurrenceRecordCount').html(occurrenceCount.toLocaleString());
    fitMapToBounds();

    $('.legendTable').html('');
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .addClass('legendTitle')
                    .html("Species" + ":")
                )
            );
    <g:each status="i" var="result" in="${searchResults.results}">
        if (${result.occurrenceCount} > 0) {
            addLegendItem("${result.scientificName}", 0,0,0, colours[${i}], false);
        }
    </g:each>
}

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


function fitMapToBounds() {
    var lat_min = null, lat_max = null, lon_min = null, lon_max = null;
    var mapContextUnencoded = $('<textarea />').html(SHOW_CONF.mapQueryContext).text(); //to convert e.g. &quot; back to "

    <g:each status="i" var="result" in="${searchResults.results}">
        if (${result.occurrenceCount} > 0) {
            var jsonUrl = SHOW_CONF.biocacheServiceUrl + "/mapping/bounds.json?q=lsid:" + "${result.guid}" + "&qc=" + mapContextUnencoded + SHOW_CONF.additionalMapFilter + "&callback=?";

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
                    var mapBounds = SHOW_CONF.map.getBounds();
                    SHOW_CONF.map.fitBounds(dataBounds);
                    if (SHOW_CONF.map.getZoom() > 12) {
                        SHOW_CONF.map.setZoom(12);
                    }

                    SHOW_CONF.map.invalidateSize(true);
                }
            });
        }
    </g:each>
}

loadMap();

</asset:script>

</body>
</html>