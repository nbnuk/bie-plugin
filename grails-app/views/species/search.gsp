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
<g:set var="filterQueryString" value="${!filterQuery.isEmpty()? '&fq=' + filterQuery?.join("&fq=") : ''}"/>
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
            biocacheQueryContext: "${grailsApplication.config?.biocacheService.queryContext ?: ''}",
            geocodeLookupQuerySuffix: "${grailsApplication.config.geocode.querySuffix}",
            maxSpecies: ${grailsApplication.config?.search?.speciesLimit ?: 100},
            isNBNinns: ${(grailsApplication.config?.nbn?.inns ?: 'false').toBoolean()},
            recordsFilter: "${recordsFilter}",
            isCompactLayout: ${compactResults},
            isNBNni: ${(grailsApplication.config?.nbn?.region ?: '') == 'Northern Ireland'}
        }
    </asset:script>
    <g:if test="${grailsApplication.config.search?.mapResults == 'true'}">
        <asset:javascript src="search.mapping.js"/>
    </g:if>

</head>

<body class="general-search page-search">

<section class="container">

    <header class="pg-header">
        <div class="row">
            <div class="col-sm-9">
                <g:if test="${grailsApplication.config?.nbn?.inns == 'true'}">
                    <h1>
                        Wales INNS portal<g:if test="${searchResults.queryTitle != 'all records' && searchResults.queryTitle != '*:*'}"> for <strong>${searchResults.queryTitle}</strong></g:if>
                    </h1>
                    This page provides information on the ${grailsApplication.config?.nbn?.innsSpeciesCount?: ""} invasive non-native species currently of most interest to Wales<br/>
                    <small>
                        By accessing records via the web service users accept that any <a title="data license" href="https://docs.nbnatlas.org/data-licenses/">CC-BY-NC</a> licenced records must not be used for commercial purposes without the permission of the data provider and all data providers must be acknowledged as required.
                    </small>
                </g:if>
                <g:elseif test="${(grailsApplication.config?.nbn?.region?:"") == 'Northern Ireland' && compactResults}">
                    <g:if test="${filterQuery.contains("listMembership_m_s:\"Northern Ireland Priority Species\"") /* TODO: refactor this into config */}">
                    <h1>NI Priority Species</h1>
                    <p>Priority species require conservation action because of their decline, rarity and importance in an all-Ireland and UK context. During the preparation of the Northern Ireland Biodiversity Strategy (2002) an initial list of 271 Northern Ireland Priority Species requiring conservation action was identified. A more comprehensive list of Northern Ireland Priority Species was later published in March 2004.</p>
                    <p>In 2007 the Northern Ireland Priority Species was reviewed to include UK priority species occurring in Northern Ireland as well as threatened Irish species and species requiring conservation action. The new Northern Ireland Priority Species list stands at 481 species, an increase from 271 on the original list. There is currently a further review of this Northern Ireland Priority Species list planned for completion 2019.</p>
                    <p>Further information can be found <a href="http://www.habitas.org.uk/priority/intro.html">here</a>.</p>
                    </g:if>
                    <g:elseif test="${filterQuery.contains("listMembership_m_s:\"Non-native species of interest to Northern Ireland\"")}">
                        <h1>Invasive Species</h1>
                        <p>If you have seen an invasive species within Northern Ireland please submit your record to <a href="https://www2.habitas.org.uk/records/ISI">CEDaR Online Recording</a>.</p>
                        <p>Submission of your record will send an immediate alert to a team of experts who will verify the record and take appropriate action.</p>
                        <p>For further information on invasive species in Northern Ireland, including species range, policy related to individual species or species groups and action plans for species that threaten the biodiversity and economy of Northern Ireland, visit <a href="http://invasivespeciesireland.com" title="Invasive Species Ireland" target="_new">Invasive Species Ireland</a>.</p>
                    </g:elseif>
                    <g:elseif test="${filterQuery.contains("listMembership_m_s:\"Northern Ireland Environment Agency - Sensitive species Northern Ireland\"")}">
                        <h1>Sensitive Species</h1>
                        <p>Environmentally sensitive information is any which, if released to the public, would result in an ‘adverse effect’ on a feature of the environment. The list of species considered as sensitive in Northern Ireland has been compiled by the Northern Ireland Environment Agency (NIEA) considering threats such as disturbance, egg collection, commercial fishing, collecting, physical harm, destruction or damage of roosts, persecution, etc. This list will be periodically reviewed both by NBN Trust and NIEA.</p>
                        <p>All data supplied to the NBN Atlas are displayed at the spatial resolution submitted by data providers, except records of species on the NBN Atlas sensitive species lists. Sensitive species records will be only available publicly on the NBN Atlas (to view or download) at the spatial resolution detailed on the sensitive species list (a resolution at which the risk of harm to a species is considered acceptable) Date information will also be reduced in quality to prevent location information being inferred through a common recorder name and date of survey. Access to higher resolution sensitive species records will be available via the NBN Atlas upon request, provided approval from the data partner is granted.</p>
                    </g:elseif>
                </g:elseif>
                <g:else>
                    <h1>
                        Search for <strong>${searchResults.queryTitle != "*:*"? searchResults.queryTitle : 'everything'}</strong>
                        returned <g:formatNumber number="${searchResults.totalRecords}" type="number"/>
                        <g:if test="${filterQuery.contains("idxtype:TAXON")}">
                            <g:if test="${searchResults.totalRecords != 1}">
                                taxa
                            </g:if>
                            <g:else>
                                taxon
                            </g:else>
                        </g:if>
                        <g:else>
                            results
                        </g:else>
                    </h1>
                </g:else>
            </div>

            <div class="col-sm-3">
                <div id="related-searches" class="related-searches hide">
                    <g:if test="${grailsApplication.config?.nbn?.inns == 'true' }">
                        <h4>Useful links</h4>
                    </g:if>
                    <g:elseif test="${grailsApplication.config?.nbn?.region?: "" == 'Northern Ireland' && compactLayout}">
                        <!-- nothing here -->
                    </g:elseif>
                    <g:else>
                        <h4>Related Searches</h4>
                    </g:else>
                    <ul class="list-unstyled">
                    <g:if test="${grailsApplication.config?.nbn?.inns == 'true' && grailsApplication.config?.search?.viewall }">
                        <li>
                            View all <a href="${grailsApplication.config?.search?.viewall}" alt="View" title="View occurrences records for all ${grailsApplication.config?.nbn?.innsSpeciesCount?: ""} INNS taxa">occurrence records</a>
                        </li>
                    </g:if>
                    <g:if test="${grailsApplication.config?.nbn?.inns == 'true' && grailsApplication.config?.download?.allcsv }">
                        <li>Download Wales + 20km buffer records for all species as: <a href="${grailsApplication.config?.download?.allcsv}" alt="Download CSV" title="Download occurrences records for all ${grailsApplication.config?.nbn?.innsSpeciesCount?: ""} INNS taxa in a CSV file">CSV</a>
                        <g:if test="${grailsApplication.config?.nbn?.inns == 'true' && grailsApplication.config?.download?.allshp }">
                            <a href="${grailsApplication.config?.download?.allshp}" alt="Download Shapefile" title="Download occurrences records for all ${grailsApplication.config?.nbn?.innsSpeciesCount?: ""} INNS taxa in a SHP file">SHP</a>
                        </g:if>
                        </li>
                    </g:if>
                    </ul>
                </div>
            </div>
        </div>
    </header>

    <div class="section">
        <div class="row">
            <div class="col-sm-12">
                <span class="col-sm-9" <g:if
                        test="${grailsApplication.config?.nbn?.inns == 'true' && grailsApplication.config?.biocacheService?.altQueryContext}">id="free-text-search-left-of-alt-query"</g:if>>
                    <g:if test="${grailsApplication.config?.search?.includeFreeTextFilterOnResults == 'true'}">
                        <form method="get"
                              action="${grailsApplication.config.bie.baseURL}${grailsApplication.config.bie.searchPath}"
                              role="search" class="navbar-form form-group" style="margin-bottom:0"
                              id="freetext-filter-form">
                            <div class="input-group" style="width:100%">
                                <input type="text" autocomplete="off" placeholder="SEARCH" name="q" title="Search"
                                       class="form-control ac_input general-search" id="freetext-filter"
                                       <g:if test="${!query.isEmpty() && query != "*:*"}">value="${query.encodeAsHTML()}"</g:if>>

                                <g:if test="${params.fq}">
                                    <g:each in="${filterQuery}" var="fq">
                                        <input type="hidden" name="fq" value='${fq}'/>
                                    </g:each>
                                </g:if>
                                <g:if test="${grailsApplication.config?.nbn?.inns == 'true'}">
                                    %{-- hardcoded change to sort-by and ordering --}%
                                    <input type="hidden" name="sortField" value='score'/>
                                    <input type="hidden" name="dir" value='desc'/>
                                </g:if>
                                <g:else>
                                    <g:if test="${params.sortField}">
                                        <input type="hidden" name="sortField" value='${params.sortField}'/>
                                    </g:if>
                                    <g:if test="${params.dir}">
                                        <input type="hidden" name="dir" value='${params.dir}'/>
                                    </g:if>
                                </g:else>
                                <g:if test="${params.rows}">
                                    <input type="hidden" name="rows" value='${params.rows}'/>
                                </g:if>
                                <g:if test="${params.includeRecordsFilter}">
                                    <input type="hidden" name="includeRecordsFilter"
                                           value='${params.includeRecordsFilter}'/>
                                </g:if>
                                <span class="input-group-btn" id="freetext-filter-buttons">
                                    <input type="submit" class="form-control btn btn-primary" alt="Search"
                                           value="Search"/>
                                    <input type="reset" class="form-control btn btn-primary" alt="Reset" value="Reset"
                                           onclick="$('#freetext-filter').val('');
                                           $('#freetext-filter-form').submit();
                                           return true;"/>
                                </span>
                            </div>
                        </form>
                    </g:if>
                </span>

                <span class="col-sm-3" id="biocacheContextPick">
                    <g:if test="${grailsApplication.config?.nbn?.inns == 'true' && grailsApplication.config?.biocacheService?.altQueryContext}">
                        <form method="get"
                              action="${grailsApplication.config.bie.baseURL}${grailsApplication.config.bie.searchPath}"
                              role="search" id="records-include-filter-form">
                            <div class="input-group">
                                <label for="includeRecordsFilter">Include records for</label>
                                <select class="form-control input-sm" id="includeRecordsFilter"
                                        name="includeRecordsFilter" onchange="this.form.submit()">
                                    <option value="biocacheService-queryContext" ${recordsFilterToggle == '' || recordsFilterToggle == 'biocacheService-queryContext' ? 'selected="selected"' : ''}>Wales</option>
                                    <option value="biocacheService-altQueryContext" ${recordsFilterToggle == 'biocacheService-altQueryContext' ? 'selected="selected"' : ''}>Wales + 20km buffer</option>
                                </select>
                                <g:if test="${params.fq}">
                                    <g:each in="${filterQuery}" var="fq">
                                        <input type="hidden" name="fq" value='${fq}'/>
                                    </g:each>
                                </g:if>
                                <g:if test="${params.q}">
                                    <input type="hidden" name="q" value='${params.q}'/>
                                </g:if>
                                <g:if test="${params.sortField}">
                                    <input type="hidden" name="sortField" value='${params.sortField}'/>
                                </g:if>
                                <g:if test="${params.dir}">
                                    <input type="hidden" name="dir" value='${params.dir}'/>
                                </g:if>
                                <g:if test="${params.rows}">
                                    <input type="hidden" name="rows" value='${params.rows}'/>
                                </g:if>
                            %{-- page will be reset, since we don't know if there might be fewer records this time --}%
                            </div>
                        </form>
                    </g:if>
                </span>

            </div>
        </div>
    </div>

    <div class="main-content panel panel-body">
        <g:if test="${searchResults.totalRecords}">
            <g:set var="paramsValues" value="${[:]}"/>
            <g:if test="${!(compactResultsRemoveFacets && compactResults)}">
                <div class="row">
                    <div class="col-sm-3">

                        <div class="well refine-box">
                            <h2 class="hidden-xs">Refine results</h2>
                            <h2 class="visible-xs"><a href="#refine-options" data-toggle="collapse"><span class="glyphicon glyphicon-chevron-down" aria-hidden="true"></span> Refine results</a>
                            </h2>

                            <div id="refine-options" class="collapse mobile-collapse">
                <g:if test="${query && filterQuery}">
                    <g:set var="queryParam">q=${query.encodeAsHTML()}<g:if
                            test="${!filterQuery.isEmpty()}">&fq=${filterQuery?.join("&fq=")}</g:if></g:set>
                </g:if>
                <g:else>
                    <g:set var="queryParam">q=${query.encodeAsHTML()}<g:if
                            test="${params.fq}">&fq=${fqList?.join("&fq=")}</g:if></g:set>
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
                                        <g:message code="facet.${item.key}" default="${item.key}"/>: <strong><g:message
                                            code="${item.key}.${item.value}" default="${item.value}"/></strong>
                                    </g:else>
                                    <a href="#" onClick="javascript:removeFacet(${facetIdx});
                                    return true;" title="remove filter"><span
                                            class="glyphicon glyphicon-remove-sign"></span></a>
                                </li>
                            </g:each>
                        </ul>
                    </div>
                </g:if>
                <g:if test="${!query.isEmpty() && query != "*:*"}">
                <div class="refine-list" id="facet-includeSynonyms">
                    <h3>Synonym matches</h3>
                    <g:if test="${includeSynonyms}">
                        <a href="?${queryParam}${appendQueryParam}&includeSynonyms=off">Exclude synonym matches</a>
                    </g:if>
                    <g:else>
                        <a href="?${queryParam}${appendQueryParam}&includeSynonyms=on">Include synonym matches</a>
                    </g:else>
                </div>
                </g:if>
                <!-- facets -->

                <g:each var="facetResult" in="${searchResults.facetResults}">
                    <g:if test="${!facetMap?.get(facetResult.fieldName) && !filterQuery?.contains(facetResult.fieldResult?.opt(0)?.label) && !facetResult.fieldName?.contains('idxtype1') && facetResult.fieldResult.length() > 0}">

                        <div class="refine-list" id="facet-${facetResult.fieldName}">
                            <h3><g:message code="facet.${facetResult.fieldName}"
                                           default="${facetResult.fieldName}"/></h3>


                        <ul class="list-unstyled">
                            <g:set var="lastElement"
                                   value="${facetResult.fieldResult?.get(facetResult.fieldResult.length() - 1)}"/>
                            <g:if test="${lastElement.label == 'before'}">
                                <li><g:set var="firstYear"
                                           value="${facetResult.fieldResult?.opt(0)?.label.substring(0, 4)}"/>
                                    <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[* TO ${facetResult.fieldResult.opt(0)?.label}]">Before ${firstYear}</a>
                                    (<g:formatNumber number="${lastElement.count}" type="number"/>)
                                </li>
                            </g:if>

                            <g:set var="hiddenValues" value="0"/>
                            <g:each var="fieldResult" in="${facetResult.fieldResult}" status="vs">
                                <g:if test="${fieldResult?.hideThisValue}">
                                    <g:set var="hiddenValues" value="${hiddenValues.toInteger()+1}"/>
                                </g:if>
                                <g:if test="${!fieldResult?.hideThisValue}">
                                    <g:if test="${(vs-hiddenValues.toInteger()) == 5 }">
                                        </ul>
                                        <ul class="collapse list-unstyled">
                                    </g:if>
                                    <g:set var="dateRangeTo"><g:if
                                            test="${vs == lastElement}">*</g:if><g:else>${facetResult.fieldResult[vs + 1]?.label}</g:else></g:set>
                                    <g:if test="${facetResult.fieldName?.contains("occurrence_date") && fieldResult.label?.endsWith("Z")}">
                                        <li><g:set var="startYear" value="${fieldResult.label?.substring(0, 4)}"/>
                                            <a href="?${queryParam}${appendQueryParam}&fq=${facetResult.fieldName}:[${fieldResult.label} TO ${dateRangeTo}]">${startYear} - ${startYear + 10}</a>
                                            (<g:formatNumber number="${fieldResult.count}" type="number"/>)</li>
                                    </g:if>
                                    <g:elseif test="${fieldResult.label?.endsWith("before")}"><%-- skip --%></g:elseif>
                                    <g:elseif test="${fieldResult.label?.isEmpty()}">
                                    </g:elseif>
                                    <g:elseif
                                            test="${fieldResult.count == (searchResults?.totalRecords ?: 0) && (grailsApplication.config.search?.hideFacetsThatDoNotFilterFurther == 'true')}">
                                    </g:elseif>
                                    <g:else>
                                        <li><a href="?${queryStringWithoutOffset}&fq=${facetResult.fieldName}:%22${fieldResult.label}%22">
                                            <g:message code="${facetResult.fieldName}.${fieldResult.label}"
                                                       default="${fieldResult.label ?: "[unknown]"}"/>
                                        </a>
                                            (<g:formatNumber number="${fieldResult.count}" type="number"/>)
                                        </li>
                                    </g:else>
                                </g:if>
                            </g:each>
                        </ul>
                            <g:if test="${facetResult.fieldResult.size()-hiddenValues.toInteger() > 5}">
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
            </g:if>

            <g:if test="${compactResultsRemoveFacets && compactResults}">
                <div class="col-sm-12">
            </g:if>
            <g:else>
                <div class="col-sm-9">
            </g:else>

        <g:if test="${idxTypes.contains("TAXON") || (grailsApplication.config.nbn?.alwaysshowdownloadbutton?:'') == 'true'}">
            <div class="download-button pull-right">
                <g:set var="downloadUrl"
                       value="${grailsApplication.config.bie.index.url}/download?${searchResultsQuery}${filterQueryString}${((grailsApplication.config.bieService.queryContext?:'.').substring(0,1) != '&') ? "&" : "" }${grailsApplication.config.bieService.queryContext}"/>
                <a class="btn btn-default active btn-small" href="${downloadUrl}"
                   title="Download a list of taxa for your search">
                    <i class="glyphicon glyphicon-download"></i>
                    Download
                </a>
            </div>
        </g:if>
        <g:if test="${grailsApplication.config?.search?.mapResults == 'true'}">
            <div id="tabs" class="taxon-tabs">
                <ul class="nav nav-tabs">
                    <li class="active"><a id="t1" href="#tabs-1" data-toggle="tab"><g:if test="${grailsApplication.config?.nbn?.inns == 'true'}">Taxa</g:if><g:else>Results</g:else></a></li>
                    <li><a id="t2" href="#tabs-2" data-toggle="tab">Map</a></li>
                </ul>

                <div id="tabs-1" class="tab-content">
                    <g:include controller="tabcomponent" action="results"/>
        </g:if>
                    <g:if test="${!compactResults}">
                      <div class="result-options">
                        <span class="record-cursor-details">Showing <b>${(params.offset ?: 0).toInteger() + 1} - ${Math.min((params.offset ?: 0).toInteger() + (params.rows ?: (grailsApplication.config?.search?.defaultRows ?: 10)).toInteger(), (searchResults?.totalRecords ?: 0))}</b> of <b>${searchResults?.totalRecords}</b> <g:if test="${grailsApplication.config?.nbn?.inns == 'true'}">taxa</g:if><g:else>results</g:else></span>


                        <form class="form-inline">
                            <div class="form-group">
                                <label for="per-page"><g:if test="${grailsApplication.config?.nbn?.inns == 'true'}">Taxa</g:if><g:else>Results</g:else> per page</label>
                                <select class="form-control input-sm" id="per-page" name="per-page">
                                    <option value="10" ${(params.rows == '10' || (!params.rows && grailsApplication.config?.search?.defaultRows == '10')) ? "selected=\"selected\"" : ""}>10</option>
                                    <option value="20" ${(params.rows == '20' || (!params.rows && grailsApplication.config?.search?.defaultRows == '20')) ? "selected=\"selected\"" : ""}>20</option>
                                    <option value="50" ${(params.rows == '50' || (!params.rows && grailsApplication.config?.search?.defaultRows == '50')) ? "selected=\"selected\"" : ""}>50</option>
                                    <option value="100" ${(params.rows == '100' || (!params.rows && grailsApplication.config?.search?.defaultRows == '100')) ? "selected=\"selected\"" : ""}>100</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="sort-by">Sort by</label>
                                <select class="form-control input-sm" id="sort-by" name="sort-by">
                                    <!-- <option value="score" ${(params.sortField == 'score' || (!params.sortField && grailsApplication.config?.search?.defaultSortField == 'score')) ? "selected=\"selected\"" : ""}>best match</option> -->
                                    <option value="scientificName" ${(params.sortField == 'scientificName' || (!params.sortField && grailsApplication.config?.search?.defaultSortField == 'scientificName')) ? "selected=\"selected\"" : ""}>scientific name</option>
                                    <option value="commonNameSingle" ${(params.sortField == 'commonNameSingle' || (!params.sortField && grailsApplication.config?.search?.defaultSortField == 'commonNameSingle')) ? "selected=\"selected\"" : ""}>common name</option>
                                    <option value="rank" ${(params.sortField == 'rank' || (!params.sortField && grailsApplication.config?.search?.defaultSortField == 'rank')) ? "selected=\"selected\"" : ""}>taxon rank</option>
                                    %{-- <option value="occurrenceCount" ${(params.sortField == 'occurrenceCount') ? "selected=\"selected\"" : ""}>occurrences</option> --}%
                                    %{-- this sorts by overall taxon occurrenceCount, not the occurrences within the fq'd results, which are inserted one by one (I assume) on the species on the page of results --}%
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="sort-order">Sort order</label>
                                <select class="form-control input-sm" id="sort-order" name="sort-order">
                                    <option value="asc" ${(params.dir == 'asc' || (!params.dir && grailsApplication.config?.search?.defaultSortOrder == 'asc')) ? "selected=\"selected\"" : ""}>ascending</option>
                                    <option value="desc" ${(params.dir == 'desc' || (!params.dir && grailsApplication.config?.search?.defaultSortOrder == 'desc') || (!params.dir && !grailsApplication.config?.search?.defaultSortOrder)) ? "selected=\"selected\"" : ""}>descending</option>
                                </select>
                            </div>

                        </form>


                        </div><!-- result-options -->
                    </g:if>

                    <input type="hidden" value="${pageTitle}" name="title"/>

                    <g:if test="${compactResults}">
                        <g:each var="pageGroup" in="${pageGroups}" status="i">
                            <div class="facetGroupName" id="heading_${i}">
                                <a href="#" class="showHidePageGroup" data-name="${i}">
                                    <span class="caret right-caret"></span>&nbsp;${pageGroup}
                                </a>
                            </div>
                            <div class="facetsGroup" id="group_${i}" style="display:none;">
                                <ol id="search-results-list" class="search-results-list list-unstyled search-results-list-compact">
                                <g:each var="result" in="${searchResults.results}">
                                    <g:set var="grp"><g:if test="${(result[pageGroupBy]?:"") instanceof Collection}">${result[pageGroupBy][0]?:""}</g:if><g:else>${result[pageGroupBy]?:""}</g:else></g:set>

                                    <g:if test="${grp.toLowerCase() == pageGroup.toLowerCase() || (grp == "" && pageGroup == 'Ungrouped')}">
                                        <li class="search-result search-result-compact clearfix">
                                        <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON' || true}">
                                            <g:set var="taxonPageLink">${request.contextPath}/species/${result.guid ?: result.linkIdentifier}</g:set>
                                            <g:set var="acceptedPageLink">${request.contextPath}/species/${result.acceptedConceptID ?: result.guid ?: result.linkIdentifier}</g:set>

                                            <h3>${result.rank}:
                                                <a href="${acceptedPageLink}"><bie:formatSciName rankId="${result.rankID}"
                                                                                             taxonomicStatus="${result.taxonomicStatus}"
                                                                                             nameFormatted="${result.nameFormatted}"
                                                                                             nameComplete="${result.nameComplete}"
                                                                                             name="${result.name}"
                                                                                             acceptedName="${result.acceptedConceptName}"/></a>
                                                <g:if test="${result.commonNameSingle}">
                                                    <span class="commonNameSummary">&nbsp;&ndash;&nbsp;${result.commonNameSingle}</span>
                                                </g:if>
                                            </h3>
                                        </g:if>
                                        </li>
                                    </g:if>
                                </g:each>
                                </ol>
                            </div>
                        </g:each>
                    </g:if>
                    <g:else>
                    <ol id="search-results-list" class="search-results-list list-unstyled">

                        <g:each var="result" in="${searchResults.results}">

                                <li class="search-result clearfix">

                                    <g:set var="sectionText"><g:if
                                            test="${!facetMap.idxtype}"><span><b>Section:</b> <g:message
                                                code="idxType.${result.idxType}"/></span></g:if></g:set>
                                    <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                        <g:set var="taxonPageLink">${request.contextPath}/species/${result.guid ?: result.linkIdentifier}</g:set>
                                        <g:set var="acceptedPageLink">${request.contextPath}/species/${result.acceptedConceptID ?: result.guid ?: result.linkIdentifier}</g:set>
                                        <g:if test="${result.image}">
                                            <div class="result-thumbnail">
                                                <a href="${acceptedPageLink}">
                                                    <img src="${grailsApplication.config.image.thumbnailUrl}${result.image}"
                                                         alt="">
                                                </a>
                                            </div>
                                        </g:if>

                                        <h3>
                                            <a href="${acceptedPageLink}"><bie:formatSciName rankId="${result.rankID}"
                                                                                             taxonomicStatus="${result.taxonomicStatus}"
                                                                                             nameFormatted="${result.nameFormatted}"
                                                                                             nameComplete="${result.nameComplete}"
                                                                                             name="${result.name}"
                                                                                             acceptedName="${result.acceptedConceptName}"/></a><!--
                                            --><g:if test="${result.commonNameSingle}"><span
                                                class="commonNameSummary">&nbsp;&ndash;&nbsp;${result.commonNameSingle}</span></g:if><!--
                                            --><g:if test="${result.establishmentMeans && ((result?.establishmentMeans?:'') == 'Non-native')}"><span
                                                    class="establishmentMeans">&nbsp;non-native</span></g:if>
                                        </h3>
                                        <p class="taxonGroup_s">${result.rank.capitalize()}<!--
                                     --><g:if test="${result.has("taxonGroup_s") && result.taxonGroup_s}"><!--
                                         -->, ${result.taxonGroup_s.capitalize()}<!--
                                    --></g:if><!--
                                    --><g:if test="${result.has("habitat_m_s") && result.habitat_m_s}"><!--
<                                        -->, ${result.habitat_m_s.join(', ').replaceAll("\"", "").capitalize()}
                                        </g:if>

                                        <g:if test="${result.has("commonName") && result.commonName && result.commonName != result.commonNameSingle}">
                                            <p class="alt-names">
                                                <g:set var="hasAtLeastOneNameListed" value="${false}"/>
                                                <g:each var="cName"
                                                        in="${result.commonNameHighlighted.split(",")}"
                                                        status="counter"><g:if test="${cName.trim().toLowerCase().replaceAll("<b>","").replaceAll("</b>","") != result.commonNameSingle.toLowerCase()}"><g:if test="${counter && hasAtLeastOneNameListed}">, </g:if>${raw(cName.trim())}<g:set var="hasAtLeastOneNameListed" value="${true}"/></g:if></g:each>
                                            </p>
                                        </g:if>

                                        <g:if test="${result.has("synonymComplete") && result.synonymComplete &&
                                                result.synonymComplete.any{ it != result.name } && /* dont show naked name synonym */
                                                result.synonymComplete.findAll{it != result.name}.any{ it.toLowerCase().contains(searchResults.queryTitle.toLowerCase()) } /* crude check if a synonym contains search term */ }">
                                            <p class="alt-names">Previous/synonymised names:
                                                ${raw(result.synonymCompleteHighlighted.findAll{it != result.name}.join(', ').replaceAll("\"", "")) /* use raw because synonymCompleteHighlighted contains html markup */}</p>
                                        </g:if>




                                        <g:if test="${taxonPageLink != acceptedPageLink}"><p
                                                class="alt-names"></p></g:if>
                                        <g:each var="fieldToDisplay"
                                                in="${grailsApplication.config.additionalResultsFields.split(",")}">
                                            <g:if test='${result."${fieldToDisplay}"}'>
                                                <g:if test='${result."${fieldToDisplay}" instanceof Collection}'>
                                                    <g:each var="fieldVal" in="${result."${fieldToDisplay}"}">
                                                        <p class="summary-info"><strong><g:message
                                                                code="${fieldToDisplay}"
                                                                default="${fieldToDisplay}"/>:</strong>
                                                            ${fieldVal}
                                                        </p>
                                                    </g:each>
                                                </g:if>
                                                <g:else>
                                                    <p class="summary-info"><strong><g:message code="${fieldToDisplay}"
                                                                                               default="${fieldToDisplay}"/>:</strong>
                                                        ${result."${fieldToDisplay}"}
                                                    </p>
                                                </g:else>
                                            </g:if>
                                        </g:each>
                                    </g:if>

                                    <g:elseif test="${result.has("idxtype") && result.idxtype == 'COMMON'}">
                                        <g:set var="speciesPageLink">${request.contextPath}/species/${result.taxonGuid ?: result.linkIdentifier}</g:set>
                                        <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                            <a href="${speciesPageLink}">${result.name}</a></h4>
                                    </g:elseif>
                                    <g:elseif test="${result.has("idxtype") && result.idxtype == 'IDENTIFIER'}">
                                        <g:set var="speciesPageLink">${request.contextPath}/species/${result.taxonGuid ?: result.linkIdentifier}</g:set>
                                        <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                            <a href="${speciesPageLink}">${result.guid}</a></h4>
                                    </g:elseif>
                                    <g:elseif test="${result.has("idxtype") && result.idxtype == 'REGION'}">
                                        <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                            <a href="${grailsApplication.config.regions.baseURL}/feature/${result.guid}">${result.name}</a>
                                        </h4>

                                        <p>
                                            <span>${result?.description && result?.description != result?.name ? result?.description : ""}</span>
                                        </p>
                                    </g:elseif>
                                    <g:elseif test="${result.has("idxtype") && result.idxtype == 'LOCALITY'}">
                                        <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                        <bie:constructEYALink result="${result}">
                                            ${result.name}
                                        </bie:constructEYALink>
                                        </h4>

                                        <p>
                                            <span>${result?.description ?: ""}</span>
                                        </p>
                                    </g:elseif>
                                    <g:elseif test="${result.has("idxtype") && result.idxtype == 'LAYER'}">
                                        <h4><g:message code="idxtype.${result.idxtype}"/>:
                                            <a href="${grailsApplication.config.spatial.baseURL}?layers=${result.guid}">${result.name}</a>
                                        </h4>

                                        <p>
                                            <g:if test="${result.dataProviderName}"><strong>Source: ${result.dataProviderName}</strong></g:if>
                                        </p>
                                    </g:elseif>
                                    <g:elseif test="${result.has("name")}">
                                        <h4><g:message code="idxtype.${result.idxtype}" default="${result.idxtype}"/>:
                                            <a href="${result.guid}">${result.name}</a></h4>

                                        <p>
                                            <span>${result?.description ?: ""}</span>
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
                                    <g:elseif test="${result.has("highlight") && result.get("highlight") && false /* hidden for now */}">
                                        <h4><g:message code="idxtype.${result.idxtype}"/>:
                                            <a href="${result.guid}">${result.name}</a></h4>

                                        <p>
                                            <span>${result.highlight}</span>
                                        </p>
                                    </g:elseif>
                                    <g:else>
                                        <h4><g:message code="idxtype.${result.idxtype}"/> TEST: <a
                                                href="${result.guid}">${result.name}</a></h4>
                                    </g:else>
                                    <g:if test="${result.has("highlight") && false /* hidden for now */}">
                                        <p><bie:displaySearchHighlights highlight="${result.highlight}"/></p>
                                    </g:if>
                                    <g:if test="${result.has("idxtype") && result.idxtype == 'TAXON'}">
                                        <ul class="summary-actions list-inline">
                                            <g:if test="${result.rankID < 7000}">
                                                <li><g:link controller="species" action="imageSearch"
                                                            params="[id: result.guid]">View images of species within this ${result.rank}</g:link></li>
                                            </g:if>

                                            <g:if test="${grailsApplication.config.sightings.guidUrl}">
                                                <li><a href="${grailsApplication.config.sightings.guidUrl}${result.guid}">Record a sighting/share a photo</a>
                                                </li>
                                            </g:if>
                                            <g:if test="${grailsApplication.config.occurrenceCounts.enabled.toBoolean() && (result?.occurrenceCount ?: 0 > 0 || grailsApplication.config?.search?.showZeroOccurrences == "true")}">
                                                <li>
                                                    <a href="${biocacheUrl}/occurrences/search?q=lsid:${result.guid}&fq=${recordsFilter}">Occurrences:
                                                        <g:formatNumber number="${result.occurrenceCount ?: 0}"
                                                                        type="number"/></a>
                                                </li>
                                            </g:if>
                                            <g:if test="${result.acceptedConceptID && result.acceptedConceptID != result.guid}">
                                                <li><g:link controller="species" action="show"
                                                            params="[guid: result.guid]"><g:message
                                                        code="taxonomicStatus.${result.taxonomicStatus}"
                                                        default="${result.taxonomicStatus}"/></g:link></li
                                            </g:if>
                                        </ul>
                                    </g:if>
                                </li>


                        </g:each>
                    </ol><!--close results-->

                    <div>
                        <tb:paginate total="${searchResults?.totalRecords}"
                             max="${params.rows ?: (grailsApplication.config?.search?.defaultRows?:10)}"
                             action="search"
                             params="${[q: params.q, fq: params.fq, dir: (params.dir ?: (grailsApplication.config?.search?.defaultSortOrder?:'desc')), sortField: (params.sortField ?: (grailsApplication.config?.search?.defaultSortField?:'score')), rows: (params.rows ?: (grailsApplication.config?.search?.defaultRows?:10))]}"/>
                    </div>
                    </g:else>

            <g:if test="${grailsApplication.config?.search?.mapResults == 'true'}">
                </div>
                <div id="tabs-2" class="tab-content">
                    <g:include controller="tabcomponent" action="map"/>

                    <div class="result-options">

                        <div class="taxon-map">
                            <h3><span id="occurrenceRecordCount">[counting]</span> records
                                <span id="occurrenceRecordCountAll"></span>
                                from <span id="speciesCount">[counting]</span> taxa
                                <g:if test="${grailsApplication.config?.search?.mapPresenceAndAbsence == 'true'}">
                                    <span class="map-pa-container">
                                        <div id="map-pa-switch" class="map-pa-switch">
                                            <input type="radio" class="map-pa-switch-input" name="toggle" value="presence" id="map-pa-presence" checked>
                                            <label for="map-pa-presence" class="map-pa-switch-label map-pa-switch-label-off">Presence</label>
                                            <input type="radio" class="map-pa-switch-input" name="toggle" value="absence" id="map-pa-absence">
                                            <label for="map-pa-absence" class="map-pa-switch-label map-pa-switch-label-on">Absence</label>
                                            <span class="map-pa-switch-selection"></span>
                                        </div>
                                    </span>
                                </g:if>
                            </h3>
                            <g:if test="${message(code: 'overview.map.button.records.map.subtitle', default: '')}">
                                <p>${g.message(code: 'overview.map.button.records.map.subtitle')}</p>
                            </g:if>
                            <div id="leafletMap"></div>
                            <!-- RR for legend display, if needed -->
                            <div id="template" style="display:none">
                                <div class="colourbyTemplate">
                                    <a class="colour-by-legend-toggle colour-by-control tooltips" href="#"
                                                    title="Map legend - click to expand"><i class="fa fa-list-ul fa-lg"
                                                                           style="color:#333"></i>
                                    </a>

                                    <form class="leaflet-control-layers-list">
                                        <div class="leaflet-control-layers-overlays">
                                            <div style="overflow:auto;max-height:400px;">
                                                <a href="#" class="hideColourControl pull-right"
                                                                            style="padding-left:10px;"><i class="glyphicon glyphicon-remove"
                                                                             style="color:#333"></i>
                                                </a>
                                                <table class="legendTable"></table>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                            <g:if test="${grailsApplication.config.spatial.baseURL}">
                                <g:set var="mapUrl">${grailsApplication.config.spatial.baseURL}?q=lsid:(${lsids})</g:set>
                            </g:if>
                            <g:else>
                                <g:set var="mapUrl">${biocacheUrl}/occurrences/search?q=lsid:(${lsids})#tab_mapView</g:set>
                            </g:else>
                        </div>
                    </div>
                </div>
            </div> <!-- tabs -->
            </g:if> <!-- map tab -->

            </div><!--end .inner-->
        </g:if>

    </div> <!-- col-sm-9 -->
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
    <asset:script type="text/javascript">
        $(function(){
            console.log(SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix);
            $.get( SEARCH_CONF.serverName + "/geo?q=" + SEARCH_CONF.query  + ' ' + SEARCH_CONF.geocodeLookupQuerySuffix, function( searchResults ) {
                for(var i=0; i< searchResults.length; i++){
                    var $results = $('#result-template').clone(true);
                    $results.attr('id', 'results-lists');
                    $results.removeClass('hide');
                    //console.log(searchResults)
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


<asset:script type="text/javascript">
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
    noImage100Url:      "${resource(dir: 'images', file: 'noImage100.jpg')}",
    imageDialog:        '${imageViewerType}',
    addPreferenceButton: ${imageClient.checkAllowableEditRole()},
    speciesListUrl:     "${grailsApplication.config.speciesList.baseURL}",
    tagIfInList:        "${grailsApplication.config.search?.tagIfInList ?: ''}",
    tagIfInListHTML:    "${grailsApplication.config.search?.tagIfInListHTML ?: ''}",
    tagIfInLists:       "${grailsApplication.config.search?.tagIfInLists ?: ''}"
};

var MAP_CONF = {
    mapType:                    "search",
    biocacheServiceUrl:         "${grailsApplication.config.biocacheService.baseURL}",
    allResultsOccurrenceRecords:            ${allResultsOccurrenceRecords},
    pageResultsOccurrenceRecords:           ${pageResultsOccurrenceRecords},
    pageResultsOccurrencePresenceRecords:   ${pageResultsOccurrencePresenceRecords},
    pageResultsOccurrenceAbsenceRecords:    ${pageResultsOccurrenceAbsenceRecords},
    defaultDecimalLatitude:     ${grailsApplication.config.defaultDecimalLatitude ?: 0},
    defaultDecimalLongitude:    ${grailsApplication.config.defaultDecimalLongitude ?: 0},
    defaultZoomLevel:           ${grailsApplication.config.defaultZoomLevel ?: 5},
    mapAttribution:             "${raw(grailsApplication.config.skin.orgNameLong)}",
    defaultMapUrl:              "${grailsApplication.config.map.default.url}",
    defaultMapAttr:             "${raw(grailsApplication.config.map.default.attr)}",
    defaultMapDomain:           "${grailsApplication.config.map.default.domain}",
    defaultMapId:               "${grailsApplication.config.map.default.id}",
    defaultMapToken:            "${grailsApplication.config.map.default.token}",
    recordsMapColour:           "${grailsApplication.config.map.records.colour}",
    mapQueryContext:            "${recordsFilterToggle == 'biocacheService-altQueryContext'? (grailsApplication.config?.biocacheService?.altQueryContext ?: '') : (grailsApplication.config?.biocacheService?.queryContext ?: '')}",
    additionalMapFilter:        "${raw(grailsApplication.config?.additionalMapFilter ?: '')}",
    map:                        null,
    mapOutline:                 ${grailsApplication.config.map.outline ?: 'false'},
    mapEnvOptions:              "name:circle;size:4;opacity:0.8",
    mapEnvLegendTitle:          "${grailsApplication.config.map.env?.legendtitle?:''}", //not used here
    mapEnvLegendHideMax:        "${grailsApplication.config.map.env?.legendhidemaxrange?:false}", //not used here
    mapLayersLabels:            "${grailsApplication.config.map.layers?.labels?:''}", //not used here
    mapLayersColours:           "${grailsApplication.config.map.layers?.colours?:''}", //not used here
    mapLayersFqs:               "${grailsApplication.config.map?.layers?.fqs ?: ''}",
    showResultsMap:             ${grailsApplication.config?.search?.mapResults == 'true'},
    mapPresenceAndAbsence:      ${grailsApplication.config?.search?.mapPresenceAndAbsence == 'true'},
    resultsToMap:               "${(grailsApplication.config?.search?.mapPresenceAndAbsence == 'true') ? searchResultsPresence : searchResults}",
    resultsToMapJSON:           null,
    presenceOrAbsence:          "${(grailsApplication.config?.search?.mapPresenceAndAbsence == 'true') ? "presence" : ""}"
};

<g:if test="${!compactResults || !compactResultsRemoveFacets}">
tagResults("${lsids}".split("%20OR%20"));
</g:if>

<g:if test="${grailsApplication.config.search?.mapResults == 'true'}">
    <g:if test="${grailsApplication.config?.search?.mapPresenceAndAbsence == 'true'}">
        initialPresenceAbsenceMap(MAP_CONF, "${searchResultsPresence}", "${searchResultsAbsence}");
    </g:if>
    loadTheMap(MAP_CONF);
</g:if>

<g:if test="${grailsApplication.config?.search?.mapPresenceAndAbsence == 'true'}">
    setPresenceAbsenceToggle(MAP_CONF, "${searchResultsPresence}", "${searchResultsAbsence}");
</g:if>

</asset:script>
</body>
</html>
