(function(ns, w, d) {

var app = {
    run: run,
    
    initElements: initElements,
    initElementClick: initElementClick,
    initElementLocalize: initElementLocalize
    
    
};

$(d).ready(function(){
    app.run();
});

function run() {
    $('#issue_list a').click(function(){
        // $('#viewer').fadeIn('fast');
        $('#viewer').show('drop', {
            direction: 'right'
        }, 'fast');
        return false;
    });
    $('#viewer').click(function(){
        // $('#viewer').fadeOut('fast');
        $(this).hide('drop', {
            direction: 'right'
        }, 'slow');
    });
    $('#issues').width($(w).width() - $('#issues').offset().left - 30);
}

function initElements(context) {
    $('*[data-init]', context).each(function(){
        var ele = $(this);
        var methods = ele.data('init').split(',');
        for (var i = 0, max_i = methods.length; i < max_i; i++) {
            app.exec(['initElement', methods[i]], [this]);
        }
    });
}
function initElementClick(element) {
    element.addEventListener("click", app, false);
}
function initElementLocalize(element) {
    var ele = $(element);
    ele.text(ele.data('text-' + c.lang));
}
function initElementIssueProject(element) {
    
    
    
}
function initElementIssueMilestone(element) {
    
    
    
}
function initElementIssueMenu(element) {
    
    
    
}
function initElementIssueFilter(element) {
    
    
    
}


})(this, this, document);