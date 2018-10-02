<section class="tab-pane fade" id="records">

    <div class="pull-right btn-group btn-group-vertical">
        <a class="btn btn-default"
           href="${biocacheUrl}/occurrences/search?q=lsid:${tc?.taxonConcept?.guid ?: ''}${recordsFilterToggle? "&fq="+recordsFilter : ""}">
            <i class="glyphicon glyphicon-th-list"></i>
            View list of all
            occurrence records for this taxon (<span class="occurrenceRecordCount">[counting]</span> records)
        </a>
        <a class="btn btn-default"
           href="${biocacheUrl}/occurrences/search?q=lsid:${tc?.taxonConcept?.guid ?: ''}${recordsFilterToggle? "&fq="+recordsFilter : ""}#tab_mapView">
            <i class="glyphicon glyphicon-map-marker"></i>
            View map of all
            occurrence records for this taxon (<span class="occurrenceRecordCount">[counting]</span> records)
        </a>
    </div>

    <div id="occurrenceRecords">
        <div id="recordBreakdowns" style="display: block;">
            <h2>Charts showing breakdown of occurrence records (<span class="occurrenceRecordCount">[counting]</span> records)</h2>
            %{--<div id="chartsHint">Hint: click on chart elements to view that subset of records</div>--}%
            <div id="charts"></div>
        </div>
    </div>
</section>
