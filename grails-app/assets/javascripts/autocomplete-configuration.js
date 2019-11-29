$(document).ready(function () {
    // autocomplete
    var bieBaseUrl = "https://species-ws.nbnatlas.org"; //SEARCH_CONF.bieWebServiceUrl;
    var bieParams = { limit: 20 };
    var autoHints = ""; //SEARCH_CONF.autocompleteHints; // expects { fq: "kingdom:Plantae" }
    $.extend( bieParams, autoHints ); // merge autoHints into bieParams

    function getMatchingName(item) {
        if (item.commonNameMatches && item.commonNameMatches.length) {
            return item.commonName;
        } else {
            return item.name;
        }
    };

    function formatAutocompleteList(list) {
        var results = [];
        if (list && list.length){
            list.forEach(function (item) {
                var name = getMatchingName(item);
                results.push({label: name, value: name});
            })
        }

        return results;
    };
$("#search").autocomplete({
    /* $.ui.autocomplete({ */
        source: function (request, response) {
            bieParams.q = request.term;
            $.ajax( {
                url: bieBaseUrl + '/search/auto.json',
                dataType: "json",
                data: bieParams,
                success: function( data ) {
                    console.log(data);
                    response( formatAutocompleteList(data.autoCompleteList) );
                }
            } );
        }
    }, $(":input#autocompleteResultPage, :input#search"));
});