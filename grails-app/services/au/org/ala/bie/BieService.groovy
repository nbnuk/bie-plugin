package au.org.ala.bie

import au.org.ala.bie.webapp2.SearchRequestParamsDTO
import grails.converters.JSON
import org.apache.commons.httpclient.util.URIUtil
import org.grails.web.json.JSONObject

class BieService {

    def webService
    def grailsApplication

    //legacy, not used
    def searchBie(SearchRequestParamsDTO requestObj) {

        def queryUrl = grailsApplication.config.bie.index.url + "/search?" + requestObj.getQueryString() +
                "&facets=" + grailsApplication.config.facets
        queryUrl += "&q.op=OR"

        //add a query context for BIE - to reduce taxa to a subset
        if(grailsApplication.config.bieService.queryContext){
            queryUrl = queryUrl + "&" + URIUtil.encodeWithinQuery(grailsApplication.config.bieService.queryContext).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")  /* URLEncoder.encode: encoding &,= and : breaks these tokens for SOLR */
        }

        //add a query context for biocache - this will influence record counts
        if(grailsApplication.config.biocacheService.queryContext){
            queryUrl = queryUrl + "&bqc=" + URIUtil.encodeWithinQuery(grailsApplication.config.biocacheService.queryContext).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
        }
        log.info("queryUrl = " + queryUrl)
        def json = webService.get(queryUrl)
        JSON.parse(json)
    }

    //take a name or TVK and return the JSON for that taxa and any direct children sorted so that the query term is at the top
    //wsQueryUrl: current query URL including q= term and any other constraints
    //strOriginalQueryTerm: original search term (e.g. could be a synonym of current searched name)
    //strName: search name (encoded) - ignored if TVK is set
    //strTVK: taxon guid - takes priority over name. Only one should be != ''
    //booMatchFull: match against full name with authority (true) or not (false). Assumed that first match against naked name, as most common search
    //booAllowSynonymMatch: allow matching against synonym of entry
    //booAllowCommonMatch: allow matching against common name of entry
    //only works for family, genus, species (defined by rankID so can accommodate subgenus, etc.), not higher taxonomies
    def searchBieOnAcceptedNameOrTVK(wsQueryUrl, strOriginalQueryTerm, strName, intPage, strTVK, booMatchFull, booAllowSynonymMatch, booAllowCommonMatch) {
        def queryUrlWithoutQ = wsQueryUrl.replace("?q=" + strOriginalQueryTerm,"?q=*:*")
        def queryUrlWithoutQandPage = queryUrlWithoutQ.replace("start=" + intPage,"start=0")
        //def matchAgainst = (strTVK != ''? 'guid' : (booMatchFull? 'nameComplete' : 'scientificName'))
        def matchAgainst = (strTVK != ''? 'guid' : (booMatchFull? 'name_complete' : 'scientific_name'))
        def toMatch = (strTVK != ''? strTVK : strName)
        def matchFQ = matchAgainst + ":%22" + toMatch + "%22"
        if ((booAllowSynonymMatch || booAllowCommonMatch) && strTVK == '') { //only do this for name matches, not tvk
            matchFQ = "%28" + matchFQ +
                    (booAllowSynonymMatch? "+OR+synonym:%22" + toMatch + "%22": "") +
                    (booAllowCommonMatch? "+OR+commonName:%22" + toMatch + "%22" : "") +
                    "%29"
        }
        def haveAcceptableResults = false
        def acceptableResults = JSON.parse("{}")

        def queryUrlExactMatch = queryUrlWithoutQandPage + "&fq=taxonomicStatus:accepted&fq=" + matchFQ
        def json = webService.get(queryUrlExactMatch)
        def resJson = JSON.parse(json)
        def resultsInThisPage = resJson.searchResults?.results?.size()?: 0 //note, not totalResults since could be on 2nd or further page, beyond end of results
        if (resultsInThisPage > 0) {
                //if +1 result might need to OR all of these together, but it could create some interesting results for naked names with different accepted entries with different authorities
                //http://localhost:8080/search?fq=idxtype%3ATAXON&q=bird - only first (genus) has its child taxa included; so that would be a good test case
            if (resJson.searchResults.results[0].rankID >= 5000 && resJson.searchResults.results[0].rankID < 8000) {
                //family, genus and species taxonomic levels
                def queryUrlFGSAndChildren = queryUrlWithoutQ + "&fq=taxonomicStatus:accepted&fq=%28" + matchFQ + "+OR+parentGuid:" + resJson.searchResults.results[0].guid + "%29"
                if (resJson.searchResults.results[0].rankID >= 5000 && resJson.searchResults.results[0].rankID < 6000) {
                    queryUrlFGSAndChildren = queryUrlFGSAndChildren.replace("&sort=", "&sort2=").replace("&dir=", "&dir2=") + "&sort=rankID&dir=ASC"
                }
                json = webService.get(queryUrlFGSAndChildren)
                def resJsonWithChild = JSON.parse(json)
                if (resJsonWithChild.searchResults?.totalRecords > 0) {
                    resJsonWithChild.searchResults.queryTitle = strOriginalQueryTerm
                    acceptableResults = resJsonWithChild
                } else {
                    acceptableResults = resJson
                }
            } else {
                acceptableResults = resJson
            }
            haveAcceptableResults = true
        }


        if (haveAcceptableResults || booMatchFull || strTVK != '') { //don't try again
            acceptableResults
        } else {
            searchBieOnAcceptedNameOrTVK(wsQueryUrl, strOriginalQueryTerm, strName, intPage, strTVK, true, booAllowSynonymMatch, booAllowCommonMatch)
        }
    }

    //additional filter on occurrence records to get different occurrenceCount values for e.g. occurrence_status:absent records
    //also allows override of biocache.queryContext if occFilter includes the needed filter already
    //def searchBieOccFilter(SearchRequestParamsDTO requestObj, String occFilter, Boolean overrideBiocacheContext) {
    def searchBieOccFilter(SearchRequestParamsDTO requestObj, occFilter, overrideBiocacheContext) {

        def queryUrl = grailsApplication.config.bie.index.url + "/search?" + requestObj.getQueryString() +
                "&facets=" + grailsApplication.config.facets
        queryUrl += "&q.op=OR"

        //add a query context for BIE - to reduce taxa to a subset
        if(grailsApplication.config.bieService.queryContext){
            queryUrl = queryUrl + "&" + URIUtil.encodeWithinQuery(grailsApplication.config.bieService.queryContext).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")  /* URLEncoder.encode: encoding &,= and : breaks these tokens for SOLR */
        }

        //add a query context for biocache - this will influence record counts
        if (!overrideBiocacheContext) {
            if (grailsApplication.config.biocacheService.queryContext) {
                //watch out for mutually exclusive conditions between queryContext and occFilter, e.g. if queryContext=occurrence_status:present and occFilter=occurrence_stats:absent then will get zero records returned
                queryUrl = queryUrl + "&bqc=(" + URIUtil.encodeWithinQuery(grailsApplication.config.biocacheService.queryContext).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
                if (occFilter) {
                    queryUrl = queryUrl + "%20AND%20" + URIUtil.encodeWithinQuery(occFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
                }
                queryUrl = queryUrl + ")"
            } else {
                if (occFilter) {
                    queryUrl = queryUrl + "&bqc=(" + URIUtil.encodeWithinQuery(occFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
                }
            }
        } else {
            if (occFilter) {
                queryUrl = queryUrl + "&bqc=(" + URIUtil.encodeWithinQuery(occFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":") + ")"
            }
        }

        log.info("queryUrlOccFilter = " + queryUrl)
        def queryParam = URIUtil.encodeWithinQuery(requestObj.q).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")

        def queryPage = requestObj.start?:0

        def haveAcceptableResults = false
        def acceptableResults = JSON.parse("{}")
        def resultsInThisPage = 0

        if (! haveAcceptableResults) {
            //try accepted, match without authority
            acceptableResults = searchBieOnAcceptedNameOrTVK(queryUrl, requestObj.q, queryParam, queryPage, "", false, true, true)
            if (acceptableResults?.searchResults) haveAcceptableResults = true
        }

        if (! haveAcceptableResults) {
            //try synonyms, exact match still
            def queryUrlExactMatch = queryUrl + "&fq=scientific_name:%22" + queryParam + "%22"; //note scientific_name is case-insensitive and has various syntax chars removed for better matching
            def queryUrlExactMatchWithoutPage = queryUrlExactMatch.replace("start=" + queryPage,"start=0")
            def json = webService.get(queryUrlExactMatchWithoutPage)
            def resJson = JSON.parse(json)
            resultsInThisPage = resJson.searchResults?.results?.size()?: 0
            if (resultsInThisPage > 0) { //what if more than one result?
                acceptableResults = searchBieOnAcceptedNameOrTVK(queryUrl, requestObj.q, "", queryPage, resJson.searchResults.results[0].acceptedConceptID, false, false, false)
                if (acceptableResults?.searchResults) haveAcceptableResults = true
            } else {
                queryUrlExactMatch = queryUrl + "&fq=name_complete:%22" + queryParam + "%22";
                queryUrlExactMatchWithoutPage = queryUrlExactMatch.replace("start=" + queryPage,"start=0")
                json = webService.get(queryUrlExactMatchWithoutPage)
                resJson = JSON.parse(json)
                resultsInThisPage = resJson.searchResults?.results?.size()?: 0
                if (resultsInThisPage > 0) { //what if more than one result?
                    acceptableResults = searchBieOnAcceptedNameOrTVK(queryUrl, requestObj.q, "", queryPage, resJson.searchResults.results[0].acceptedConceptID, false, false, false)
                    if (acceptableResults?.searchResults) haveAcceptableResults = true
                } else {
                    //no synonym match
                }
            }
        }

        if (! haveAcceptableResults) {
            def queryUrlExactCommonName = queryUrl + "&fq=taxonomicStatus:accepted&fq=commonName:%22" + queryParam + "%22";
            def queryUrlExactCommonNameWithoutPage = queryUrlExactCommonName.replace("start=" + queryPage,"start=0")
            def json = webService.get(queryUrlExactCommonNameWithoutPage)
            def resJson = JSON.parse(json)
            resultsInThisPage = resJson.searchResults?.results?.size()?: 0
            if (resultsInThisPage > 0) {
                json = webService.get(queryUrlExactCommonName)
                acceptableResults = JSON.parse(json)
                haveAcceptableResults = true
            }
        }


        if (! haveAcceptableResults) {
            def queryUrlAccepted = queryUrl + "&fq=taxonomicStatus:accepted"
            def queryUrlAcceptedWithoutPage = queryUrlAccepted.replace("start=" + queryPage,"start=0")
            def json = webService.get(queryUrlAcceptedWithoutPage)
            def resJson = JSON.parse(json)
            resultsInThisPage = resJson.searchResults?.results?.size()?: 0
            if (resultsInThisPage > 0) {
                json = webService.get(queryUrlAccepted)
                acceptableResults = JSON.parse(json)
                haveAcceptableResults = true
            }
        }

        if (! haveAcceptableResults) {
            //give up?
            def json = webService.get(queryUrl)
            def resJson = JSON.parse(json)
            //TODO: need to change sort order to best-match desc maybe?
            acceptableResults = resJson
            haveAcceptableResults = true //well, maybe
        }

        //some horrible code to build fake-highlights into the synonym list
        acceptableResults?.searchResults?.results?.each { result ->
            def synonymCompleteHighlighted = []
            if (result?.synonymComplete) {
                result.synonymComplete.each {
                    if (it.toLowerCase() != result.name.toLowerCase()) { //exclude naked name synonyms
                        def startPos = it.toLowerCase().indexOf(requestObj.q.toLowerCase())
                        if (startPos >= 0) {
                            def strStart = (startPos > 0 ? it.substring(0, startPos) : '')
                            def strMatched = it.substring(startPos, startPos + requestObj.q.length())
                            def strEnd = (it.length() > startPos + requestObj.q.length() ? it.substring(startPos + requestObj.q.length()) : '')
                            synonymCompleteHighlighted.add(strStart + "<b>" + strMatched + "</b>" + strEnd)
                        } else {
                            synonymCompleteHighlighted.add(it)
                        }
                    }
                }
            }
            result.synonymCompleteHighlighted = synonymCompleteHighlighted
        }

        acceptableResults
    }

    def getSpeciesList(guid){
        if(!guid){
            return null
        }
        try {
            def json = webService.get(grailsApplication.config.speciesList.baseURL + "/ws/species/" + guid.replaceAll(/\s+/,'+') + "?isBIE=true", true)
            return JSON.parse(json)
        } catch(Exception e){
            //handles the situation where time out exceptions etc occur.
            log.error("Error retrieving species list.", e)
            return []
        }
    }

    def getSpeciesListDetails(dataResourceUid) {
        try {
            def json = webService.get(grailsApplication.config.speciesList.baseURL + "/ws/speciesList/" + (dataResourceUid ?: ""), true)
            return JSON.parse(json)
        } catch(Exception e){
            //handles the situation where time out exceptions etc occur.
            log.error("Error retrieving species list.", e)
            return []
        }
    }

    def getTaxonConcept(guid) {
        if (!guid && guid != "undefined") {
            return null
        }
        def json = webService.get(grailsApplication.config.bie.index.url + "/taxon/" + guid.replaceAll(/\s+/,'+'))
        //log.debug "ETC json: " + json
        try{
            JSON.parse(json)
        } catch (Exception e){
            log.warn "Problem retrieving information for Taxon: " + guid
            null
        }
    }

    def getClassificationForGuid(guid) {
        def url = grailsApplication.config.bie.index.url + "/classification/" + guid.replaceAll(/\s+/,'+')
        def json = webService.getJson(url)
        log.debug "json type = " + json
        if (json instanceof JSONObject && json.has("error")) {
            log.warn "classification request error: " + json.error
            return [:]
        } else {
            log.debug "classification json: " + json
            return json
        }
    }

    def getChildConceptsForGuid(guid) {
        def url = grailsApplication.config.bie.index.url + "/childConcepts/" + guid.replaceAll(/\s+/,'+')

        if(grailsApplication.config.bieService.queryContext){
            url = url + "?" + URLEncoder.encode(grailsApplication.config.bieService.queryContext, "UTF-8")
        }

        def json = webService.getJson(url).sort() { it.rankID?:0 }

        if (json instanceof JSONObject && json.has("error")) {
            log.warn "child concepts request error: " + json.error
            return [:]
        } else {
            log.debug "child concepts json: " + json
            return json
        }
    }

    def getOccurrenceCountsForGuid(guid, presenceOrAbsence, occFilter, overrideBiocacheContext, overrideAdditionalMapFilter) {

        def url = grailsApplication.config.biocacheService.baseURL + '/occurrences/taxaCount?guids=' + guid.replaceAll(/\s+/, '+')

        //add a query context for biocache - this will influence record counts
        if (!overrideBiocacheContext) {
            if (grailsApplication.config.biocacheService?.queryContext) {
                url = url + "&fq=(" + URIUtil.encodeWithinQuery(grailsApplication.config.biocacheService.queryContext).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
                if (occFilter) {
                    url = url + "%20AND%20" + URIUtil.encodeWithinQuery(occFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
                }
                url = url + ")"
            } else {
                if (occFilter) {
                    url = url + "&fq=(" + URIUtil.encodeWithinQuery(occFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":") + ")"
                }
            }
        } else {
            if (occFilter) {
                url = url + "&fq=(" + URIUtil.encodeWithinQuery(occFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":") + ")"
            }
        }

        if (!overrideAdditionalMapFilter) {
            if (grailsApplication.config?.additionalMapFilter) {
                url = url + "&" + URIUtil.encodeWithinQuery(grailsApplication.config.additionalMapFilter).replaceAll("%26","&").replaceAll("%3D","=").replaceAll("%3A",":")
            }
        }

        if (presenceOrAbsence == 'presence') {
            url = url + "&fq=-occurrence_status:absent"
        } else if (presenceOrAbsence == 'absence') {
            url = url + "&fq=occurrence_status:absent"
        }
        def json = webService.get(url)
        try{
            def response = JSON.parse(json)
            Iterator<?> keys = response.keys();
            String key = (String) keys.next()
            response.get(key)
        } catch (Exception e){
            log.info "Problem retrieving occurrence information for Taxon: " + guid
            null
        }
    }

}
