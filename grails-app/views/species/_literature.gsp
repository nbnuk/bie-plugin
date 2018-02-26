<section class="tab-pane fade" id="literature">
    <div class="row">
        <!--left-->
        <div class="col-md-3 sidebarCol">
            <div class="side-menu" id="sidebar">
                <nav class="navbar navbar-default" role="navigation">
                    <ul class="nav nav-stacked">
                        <li><a href="#bhl-integration">Biodiversity Heritage Library</a></li>
                    </ul>
                </nav>
            </div>
        </div><!--/left-->

    <!--right-->
        <div class="col-md-9" style="padding-top:14px;">

            <div id="bhl-integration">
                <h3>Name references found in the <a href="http://biodiversityheritagelibrary.com/" target="_blank">Biodiversity Heritage Library</a></h3>
                <div id="bhl-results-list" class="result-list">
                    <a href='http://www.biodiversitylibrary.org/search?SearchTerm=${synonyms?.join('%22+OR+%22')}&SearchCat=M#/names' target='bhl'>Search BHL for references to ${tc?.taxonConcept?.nameString}</a>
                </div>
            </div>
        </div><!--/right-->
    </div><!--/row-->
</section>
