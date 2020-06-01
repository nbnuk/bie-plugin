/**
 * Copyright (C) 2016 Atlas of Living Australia
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
 */
package au.org.ala.bie

import au.org.ala.bie.webapp2.SearchRequestParamsDTO
import grails.converters.JSON
import groovy.json.JsonSlurper
import org.apache.commons.lang.WordUtils
import org.grails.web.json.JSONObject
import org.apache.commons.lang.StringUtils


/**
 * Species Controller
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
class SpeciesController {
    // Caused by the grails structure eliminating the // from http://x.y.z type URLs
    static BROKEN_URLPATTERN = /^[a-z]+:\/[^\/].*/

    def bieService
    def utilityService
    def biocacheService
    def authService

    def allResultsGuids = []
    def allResultsOccs = 0
    def allResultsOccsNoMapFilter = 0
    def pageResultsOccs = 0
    def pageResultsOccsPresence = 0
    def pageResultsOccsAbsence = 0
    def recordsFilter = ''

    def pageGroups = []

    def geoSearch = {

        def searchResults = []
        try {
            def googleMapsKey = grailsApplication.config.googleMapsApiKey
            def url = "https://maps.googleapis.com/maps/api/geocode/json?key=${googleMapsKey}&address=" +
                    URLEncoder.encode(params.q, 'UTF-8')
            def response = new URL(url).text
            def js = new JsonSlurper()
            def json = js.parseText(response)

            if(json.results){
                json.results.each {
                    searchResults << [
                            name: it.formatted_address,
                            latitude: it.geometry.location.lat,
                            longitude: it.geometry.location.lng
                    ]
                }
            }
        } catch (Exception e) {
            log.error(e.getMessage(), e)
        }

        JSON.use('deep') {
            render searchResults as JSON
        }
    }

    def getRecordsFilter() {
        //for record filter toggle
        def recordsFilter = grailsApplication.config?.biocacheService?.queryContext?:""
        if (params.includeRecordsFilter) {
            if (params.includeRecordsFilter == 'biocacheService-altQueryContext') {
                recordsFilter = grailsApplication.config?.biocacheService?.altQueryContext ?: ""
            }
        }
        return recordsFilter
    }

    /**
     * Search page - display search results from the BIE (includes results for non-species pages too)
     */
    def search = {
        def query = params.q?:"".trim()
        if(query == "*" || query == "") query = "*:*"
        def filterQuery = params.list('fq') // will be a list even with only one value
        def includeSynonyms = (params.includeSynonyms?:'on') == 'on'
        def startIndex = params.offset?:0

        def showAsCompact = (grailsApplication.config?.search?.compactResults ?: 'false').toBoolean()
        if (grailsApplication.config.search?.compactResultsGroupBy?:"" != "") {
            if ((grailsApplication.config.search?.compactResultsOnlyWhenPageParam ?: 'false').toBoolean() && !(params?.compact ?: 'false').toBoolean()) {
                showAsCompact = false
            }
        }
        def rows
        if (showAsCompact) {
            rows = params.rows ?: (grailsApplication.config?.search?.compactResultsRows ?: 100)
        } else {
            rows = params.rows ?: (grailsApplication.config?.search?.defaultRows ?: 10)
        }

        def sortField = params.sortField?:(grailsApplication.config?.search?.defaultSortField?:"")
        def sortDirection = params.dir?:(grailsApplication.config?.search?.defaultSortOrder?:"desc")
        //log.info "SortField= " + sortField
        //log.info "SortDir= " + sortDirection
        if (params.dir && !params.sortField) {
            sortField = "score" // default sort (field) of "score" when order is defined on its own
        }
        def compactHeader
        if (showAsCompact) {
            sortField = 'scientificName' //hardcoded
            sortDirection = 'asc'

            if (grailsApplication.config?.search?.compact?.headers?:"") {
                def jsonSlurper = new JsonSlurper()
                def compactHeaders = jsonSlurper.parseText((grailsApplication.config?.search?.compact?.headers ?: "[]"))
                compactHeaders.each { listHeader ->
                    if (filterQuery.contains("listMembership_m_s:\"" + listHeader.list + "\"")) {
                        compactHeader = listHeader.header_html
                    }
                }
            }
        }
        recordsFilter = getRecordsFilter()

        def requestObj = new SearchRequestParamsDTO(query, filterQuery, startIndex, rows, sortField, sortDirection, includeSynonyms)
        log.info "SearchRequestParamsDTO = " + requestObj
        log.info "recordsFilter = " + recordsFilter
        //def searchResults = bieService.searchBie(requestObj)
        //def searchResults = bieService.searchBieOccFilter(requestObj, recordsFilter, true)
        def searchResultsArr = bieService.searchBieOccFilter(requestObj, recordsFilter, true)
        def searchResults = searchResultsArr[0]
        def searchResultsQuery = searchResultsArr[1]
        log.info("Actual query used: " + searchResultsQuery)
        def searchResultsPresence
        def searchResultsAbsence
        if ((grailsApplication.config?.search?.mapPresenceAndAbsence?:"") == "true") {
            if (grailsApplication.config?.biocacheService?.altQueryContext) {
                searchResultsPresence = bieService.searchBieOccFilter(requestObj, recordsFilter + " AND " + "-occurrence_status:absent", true)[0]
                searchResultsAbsence = bieService.searchBieOccFilter(requestObj, recordsFilter + " AND " + "occurrence_status:absent", true)[0]
            } else {
                searchResultsPresence = bieService.searchBieOccFilter(requestObj, "-occurrence_status:absent", false)[0]
                searchResultsAbsence = bieService.searchBieOccFilter(requestObj, "occurrence_status:absent", false)[0]
            }
        }

        def lsids = ""
        def sr = searchResults?.searchResults

        if (sr) {
            sr.results.each { result ->
                lsids += (lsids != "" ? "%20OR%20" : "") + result.guid
            }
        }

        // empty search -> search for all records
        if (query.isEmpty() || query == "") {
            //render(view: '../error', model: [message: "No search term specified"])
            query = "*:*";
        }

        if (filterQuery.size() > 1 && filterQuery.findAll { it.size() == 0 }) {
            // remove empty fq= params IF more than 1 fq param present
            def fq2 = filterQuery.findAll { it } // excludes empty or null elements
            redirect(action: "search", params: [q: query, fq: fq2, start: startIndex, rows: rows, score: sortField, dir: sortDirection])
        }

        if (searchResults instanceof JSONObject && searchResults.has("error")) {
            log.error "Error requesting taxon concept object: " + searchResults.error
            render(view: '../error', model: [message: searchResults.error])
        } else {
            setResultStats(searchResults, searchResultsPresence, searchResultsAbsence)
            if (grailsApplication.config.search?.compactResultsGroupBy?:"" != "") {
                setResultGroups(searchResults, grailsApplication.config.search?.compactResultsGroupBy)
            }
            def jsonSlurper = new JsonSlurper()
            def facetsOnlyShowValuesJson = jsonSlurper.parseText((grailsApplication.config.search?.facetsOnlyShowValues ?: "[]"))
            def tagIfInListsJson = jsonSlurper.parseText((grailsApplication.config.search?.tagIfInLists ?: "[]"))

            if (searchResults?.searchResults) {
                searchResults.searchResults.facetResults.each { facetRes ->
                    facetRes.fieldResult.each { fieldRes ->
                        facetsOnlyShowValuesJson.each { facetFilter ->
                            if (facetRes.fieldName == facetFilter.facet) {
                                if (!facetFilter.values.contains(fieldRes.fieldValue)) {
                                    fieldRes.hideThisValue = true
                                }
                            }
                        }
                    }
                }
            }


            def queryStringWithoutOffset = request.queryString?:"*:*"
            def ixOffset = queryStringWithoutOffset.indexOf("offset=")
            if (ixOffset >= 0) {
                def strBefore = queryStringWithoutOffset.substring(0, ixOffset)
                def strAfter = queryStringWithoutOffset.substring(ixOffset + "offset=".length())
                def ixAfter = strAfter.indexOf("&")
                queryStringWithoutOffset = strBefore
                if (ixAfter >= 0) {
                    queryStringWithoutOffset += strAfter.substring(ixAfter)
                }
            }

            render(view: 'search', model: [
                    searchResults: searchResults?.searchResults,
                    searchResultsPresence: searchResultsPresence?.searchResults,
                    searchResultsAbsence: searchResultsAbsence?.searchResults,
                    facetMap: utilityService.addFacetMap(filterQuery),
                    query: query?.trim(),
                    queryStringWithoutOffset: queryStringWithoutOffset,
                    searchResultsQuery: searchResultsQuery,
                    filterQuery: filterQuery,
                    includeSynonyms: includeSynonyms,
                    idxTypes: utilityService.getIdxtypes(searchResults?.searchResults?.facetResults),
                    isAustralian: false,
                    collectionsMap: utilityService.addFqUidMap(filterQuery),
                    lsids: lsids,
                    offset: startIndex,
                    allResultsOccurrenceRecords: allResultsOccs,
                    pageResultsOccurrenceRecords: pageResultsOccs,
                    pageResultsOccurrencePresenceRecords: pageResultsOccsPresence,
                    pageResultsOccurrenceAbsenceRecords: pageResultsOccsAbsence,
                    recordsFilterToggle: params.includeRecordsFilter ?: "",
                    recordsFilter: recordsFilter,
                    compactResults: showAsCompact,
                    compactHeader: compactHeader,
                    pageGroups: pageGroups,
                    pageGroupBy: grailsApplication.config?.search?.compactResultsGroupBy ?: '',
                    compactResultsRemoveFacets: (grailsApplication.config?.search?.compactResultsRemoveFacets ?: 'false').toBoolean(),
                    facetsOnlyShowValues: facetsOnlyShowValuesJson,
                    tagIfInLists: tagIfInListsJson
            ])
        }
    }

    /**
     * Species page - display information about the requested taxa
     *
     * TAXON: a taxon is 'any group or rank in a biological classification in which organisms are related.'
     * It is also any of the taxonomic units. So basically a taxon is a catch-all term for any of the
     * classification rankings; i.e. domain, kingdom, phylum, etc.
     *
     * TAXON CONCEPT: A taxon concept defines what the taxon means - a series of properties
     * or details about what we mean when we use the taxon name.
     *
     */
    def show = {
        def guid = regularise(params.guid)

        def taxonDetails = bieService.getTaxonConcept(guid)
        log.debug "show - guid = ${guid} "

        def recordsFilter = getRecordsFilter()

        if (!taxonDetails) {
            log.error "Error requesting taxon concept object: " + guid
            response.status = 404
            render(view: '../error', model: [message: "Requested taxon <b>" + guid + "</b> was not found"])
        } else if (taxonDetails instanceof JSONObject && taxonDetails.has("error")) {
            if (taxonDetails.error?.contains("FileNotFoundException")) {
                log.error "Error requesting taxon concept object: " + guid
                response.status = 404
                render(view: '../error', model: [message: "Requested taxon <b>" + guid + "</b> was not found"])
            } else {
                log.error "Error requesting taxon concept object: " + taxonDetails.error
                render(view: '../error', model: [message: taxonDetails.error])
            }
        } else if (taxonDetails.taxonConcept?.guid && taxonDetails.taxonConcept.guid != guid) {
            // old identifier so redirect to current taxon page
            redirect(uri: "/species/${taxonDetails.taxonConcept.guid}")

        } else {
            def synonymAllResultsOccs = -1

            if (taxonDetails.taxonConcept.acceptedConceptID) {
                def synonymOccsPresence = bieService.getOccurrenceCountsForGuid(taxonDetails.taxonConcept.acceptedConceptID, "presence", recordsFilter, true, false)
                def synonymOccsAbsence = bieService.getOccurrenceCountsForGuid(taxonDetails.taxonConcept.acceptedConceptID, "absence", recordsFilter, true, false)
                synonymAllResultsOccs = synonymOccsPresence + synonymOccsAbsence
                if ((pageResultsOccsPresence == null) || (synonymOccsAbsence == null)) {
                    synonymAllResultsOccs = 0
                }
            }

            def pageResultsOccsPresence = bieService.getOccurrenceCountsForGuid(taxonDetails.taxonConcept.guid, "presence", recordsFilter, true, false)
            def pageResultsOccsAbsence = bieService.getOccurrenceCountsForGuid(taxonDetails.taxonConcept.guid, "absence", recordsFilter, true, false)
            def allResultsOccs = pageResultsOccsPresence + pageResultsOccsAbsence
            if (pageResultsOccsPresence == null) {
                pageResultsOccsPresence = -1
                allResultsOccs = -1
            }
            if (pageResultsOccsAbsence == null) {
                pageResultsOccsAbsence = -1
                allResultsOccs = -1
            }
            def pageResultsOccs = allResultsOccs
            def allResultsOccsNoMapFilter = 0
            if ((grailsApplication.config?.species?.mapPresenceAndAbsence?:"") == "true") {
                //have all info needed
            } else {
                //allResultsOccs = pageResultsOccs = bieService.getOccurrenceCountsForGuid(taxonDetails.taxonConcept.guid, "all", recordsFilter, true, false)
                if (grailsApplication.config?.additionalMapFilter == "fq=occurrence_status:present" || grailsApplication.config?.additionalMapFilter == "fq=-occurrence_status:present") {
                    //for these common options don't make *another* web service call
                    allResultsOccsNoMapFilter = allResultsOccs
                } else {
                    allResultsOccsNoMapFilter = bieService.getOccurrenceCountsForGuid(taxonDetails.taxonConcept.guid, "all", recordsFilter, true, true)
                    if (allResultsOccsNoMapFilter == null) allResultsOccsNoMapFilter = -1
                }
            }
            def jsonSlurper = new JsonSlurper()
            //fake up a search results JSON object to look like that returned for species search list jsonSlurper.parseText(
            def searchResults = '{ "results": [{"occurrenceCount":"' + allResultsOccs + '", "guid":"' + taxonDetails.taxonConcept.guid + '", "scientificName":"notused"}] }'
            def searchResultsPresence = '{ "results": [{"occurrenceCount":"' + pageResultsOccsPresence + '", "guid":"' + taxonDetails.taxonConcept.guid + '", "scientificName":"notused"}] }'
            def searchResultsAbsence = '{ "results": [{"occurrenceCount":"' + pageResultsOccsAbsence + '", "guid":"' + taxonDetails.taxonConcept.guid + '", "scientificName":"notused"}] }'

            render(view: 'show', model: [
                    tc: taxonDetails,
                    synonymOccurrenceRecords: synonymAllResultsOccs,
                    searchResults: searchResults,
                    searchResultsPresence: searchResultsPresence,
                    searchResultsAbsence: searchResultsAbsence,
                    statusRegionMap: utilityService.getStatusRegionCodes(),
                    infoSourceMap:[],
                    textProperties: [],
                    synonyms: utilityService.getSynonymsForTaxon(taxonDetails),
                    isAustralian: false,
                    isRoleAdmin: false, //authService.userInRole(grailsApplication.config.auth.admin_role),
                    userName: "",
                    isReadOnly: grailsApplication.config.ranking.readonly,
                    sortCommonNameSources: utilityService.getNamesAsSortedMap(taxonDetails.commonNames),
                    taxonHierarchy: bieService.getClassificationForGuid(taxonDetails.taxonConcept.guid),
                    childConcepts: bieService.getChildConceptsForGuid(taxonDetails.taxonConcept.guid),
                    speciesList: bieService.getSpeciesList(taxonDetails.taxonConcept?.guid?:guid),
                    allResultsOccurrenceRecords: allResultsOccs,
                    allResultsOccurrenceRecordsNoMapFilter: allResultsOccsNoMapFilter,
                    pageResultsOccurrenceRecords: pageResultsOccs,
                    pageResultsOccurrencePresenceRecords: pageResultsOccsPresence,
                    pageResultsOccurrenceAbsenceRecords: pageResultsOccsAbsence,
                    recordsFilterToggle: params.includeRecordsFilter ?: "",
                    recordsFilter: recordsFilter
            ])
        }
    }

    /**
     * Display images of species for a given higher taxa.
     * Note: page is AJAX driven so very little is done here.
     */
    def imageSearch = {
        def model = [:]
        if(params.id){
            def taxon = bieService.getTaxonConcept(regularise(params.id))
            model["taxonConcept"] = taxon
        }
        model
    }

    def bhlSearch = {
        render (view: 'bhlSearch')
    }

    def soundSearch = {
        def result = biocacheService.getSoundsForTaxon(params.s)
        render(contentType: "text/json") {
            result
        }
    }

    /**
     * Do logouts through this app so we can invalidate the session.
     *
     * @param casUrl the url for logging out of cas
     * @param appUrl the url to redirect back to after the logout
     */
    def logout = {
        session.invalidate()
        redirect(url:"${params.casUrl}?url=${params.appUrl}")
    }

    /**
     * Note, 'all results' means up to the config search.speciesLimit value (which may differ from the page size)
     */
    def setResultStats (pageResults, searchResultsPresence, searchResultsAbsence) {
        allResultsGuids = []
        allResultsOccs = 0
        pageResultsOccs = 0
        pageResultsOccsPresence = 0
        pageResultsOccsAbsence = 0

        def sr
        def rows = params.rows?:(grailsApplication.config?.search?.defaultRows?:10)
        def rowsMax = grailsApplication.config?.search?.speciesLimit ?: 100
        if ((pageResults?.searchResults?.totalRecords ?: 0) > rows.toInteger()) { //must load all results
            // its horrible to call twice, once for single page and once for all results, but that seems to be what we have to do
            def query = params.q ?: "".trim()
            if (query == "*") query = ""
            def filterQuery = params.list('fq') // will be a list even with only one value
            def recordsFilter = getRecordsFilter()

            def sortField = params.sortField ?: (grailsApplication.config?.search?.defaultSortField ?: "")
            def sortDirection = params.dir ?: (grailsApplication.config?.search?.defaultSortOrder ?: "desc")

            if (params.dir && !params.sortField) {
                sortField = "score" // default sort (field) of "score" when order is defined on its own
            }

            def includeSynonyms = (params.includeSynonyms?:'off') == 'on'

            def requestObj = new SearchRequestParamsDTO(query, filterQuery, 0, rowsMax, sortField, sortDirection, includeSynonyms)
            log.info "SearchRequestParamsDTO = " + requestObj
            def searchResults = bieService.searchBieOccFilter(requestObj, recordsFilter, true)[0]

            sr = searchResults?.searchResults
        } else {
            sr = pageResults?.searchResults
        }
        if (sr) {
            sr.results.each { result ->
                allResultsGuids << result.guid
                allResultsOccs += result?.occurrenceCount?: 0
            }
        }
        sr = pageResults?.searchResults
        if (sr) {
            sr.results.each { result ->
                pageResultsOccs += result?.occurrenceCount?: 0
            }
        }

        sr = searchResultsPresence?.searchResults
        if (sr) {
            sr.results.each { result ->
                pageResultsOccsPresence += result?.occurrenceCount?: 0
            }
        }

        sr = searchResultsAbsence?.searchResults
        if (sr) {
            sr.results.each { result ->
                pageResultsOccsAbsence += result?.occurrenceCount?: 0
            }
        }
    }

    def setResultGroups (pageResults, groupField) {
        pageGroups = []
        def sr
        def areOthers = false
        sr = pageResults?.searchResults
        if (sr) {
            sr.results.each { result ->
                if (result[ groupField ]) {
                    def grp = result[ groupField ]
                    if (grp instanceof Collection) {
                        pageGroups << WordUtils.capitalize(grp[0]) //take first element - alternative is to potentially put same entry into multiple groups
                    } else {
                        pageGroups << WordUtils.capitalize(grp)
                    }
                } else {
                    areOthers = true
                }
            }
        }
        pageGroups = pageGroups.sort().unique()
        if (areOthers) pageGroups = pageGroups.plus('Ungrouped') //TODO i18n
    }

    def occurrences(){
        def title = "INNS species" //TODO
        //getAllResults()

        def url = biocacheService.performBatchSearch(allResultsGuids, title, recordsFilter)

        if(url){
            redirect(url:url)
        } else {
            redirect(controller: "species", action: "search") //TODO: need to pass URL filter params to this?
        }
    }

    private regularise(String guid) {
        if (!guid)
            return guid
        if (guid ==~ BROKEN_URLPATTERN) {
            guid = guid.replaceFirst(":/", "://")
        }
        return guid
    }

}
