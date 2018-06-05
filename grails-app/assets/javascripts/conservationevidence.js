function nbnApi(b, c) {
    var a = this;
    this.el = document.getElementById(b);
    this.searchterm = this.el.getAttribute("data-searchterm");
    this.action= parseInt(this.el.getAttribute("data-action"));
    this.study = parseInt(this.el.getAttribute("data-study"));
    this.total = parseInt(this.el.getAttribute("data-total"));
    this.errorMsg = this.el.getAttribute("data-errormsg");

    this.el.style.display = "hidden";
    this.data = {};
    this.ajax = (typeof(c) === "undefined") ? false : c;
    if ((b === undefined) || (searchterm === undefined)) {
        return null
    }
    this.buildArticle = function(d) {
        var f = document.createElement("div");
        f.className = "nbn-study-item";
        var e = document.createElement("a");
        e.className = "nbn-study-link";
        e.href = d.url;
        e.innerHTML = d.title;
        e.target = "_blank";
        f.appendChild(e);
        return f
    };
    this.buildWidget = function(d) {
        this.data = d;
        if (document.readyState === "complete") {
            this.outputWidget()
        } else {
            window.onload = this.outputWidget()
        }
    };
    this.outputWidget = function() {
        while (this.el.firstChild) {
            this.el.removeChild(this.el.firstChild)
        }
        if (this.ajax == true) {
            this.outputSearchBox();
            this.el.getElementsByTagName("button")[0].addEventListener("click", this.submitAjaxRequest)
        }
        if ((this.data == undefined) || (this.data.total_results == 0)) {
            if (this.errorMsg == undefined || this.errorMsg.length == 0) {
                this.outputErrorMessage('Sorry, there is no evidence available for: "' + this.searchterm + '".');
            } else {
                this.outputErrorMessage(this.errorMsg);
            }

            return
        } else {
            for (var d = 0; d < this.data.results.length; d++) {
                var f = this.buildArticle(this.data.results[d]);
                this.el.appendChild(f)
            }
        }
        var e = document.createElement("a");
        e.className = "nbn-study-count";
        e.href = this.data.results_url;
        e.innerHTML = this.data.total_results_copy;
        e.target = "_blank";
        this.el.appendChild(e);
        this.el.style.display = "block"
    };
    this.outputErrorMessage = function(f) {
        var d = document.createElement("p");
        d.className = "nbn-widget-error";
        var e = document.createElement("span");
        e.className = "nbn-widget-error-message";
        e.innerHTML = f;
        d.appendChild(e);
        this.el.appendChild(d)
    };
    this.submitAjaxRequest = function() {
        while (document.getElementsByTagName("head")[0].getElementsByClassName("nbn-jsonp")[0]) {
            document.getElementsByTagName("head")[0].removeChild(document.getElementsByTagName("head")[0].getElementsByClassName("nbn-jsonp")[0])
        }
        a.searchterm = a.el.getElementsByTagName("input")[0].value;
        a.requestJSONP()
    };
    this.requestJSONP = function() {

        var e = "https://www.conservationevidence.com/binomial/nbnsearch?name=" + this.searchterm + "&action=" + this.action + "&study=" + this.study +"&total=" + this.total + "&callback=nbnWidget.buildWidget";
        var d = document.createElement("script");
        d.src = e;
        d.className = "nbn-jsonp";
        document.getElementsByTagName("head")[0].appendChild(d)
    };
    this.outputSearchBox = function() {
        var f = document.createElement("div");
        f.className = "nbn-search-holder";
        var e = document.createElement("input");
        e.type = "text";
        e.className = "nbn-search-input";
        e.placeholder = "searchterm (e.g Corvus corone)";
        var d = document.createElement("button");
        d.type = "button";
        d.innerHTML = "Query";
        f.appendChild(e);
        f.appendChild(d);
        this.el.appendChild(f)
    };
    this.requestJSONP();
    return this
};