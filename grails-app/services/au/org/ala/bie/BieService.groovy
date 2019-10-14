package au.org.ala.bie

import au.org.ala.bie.webapp2.SearchRequestParamsDTO
import grails.converters.JSON
import org.apache.commons.httpclient.util.URIUtil
import org.grails.web.json.JSONObject

class BieService {

    def webService
    def grailsApplication

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
        def json = webService.get(queryUrl)
        JSON.parse(json)
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