var getFields = function(obj) {
    var key, value,
        fieldsArray = [];
    for ( key in object ) {
        if ( object.hasOwnProperty( key )) {
            value = object[ key ];
            // For each property/field add an object to the array, with key and value
            fieldsArray.push({
                key: key,
                value: value
            });
        }
    }
    // Return the array, to be rendered using {{for ~fields(object)}}
    return fieldsArray;
}

var doSomething = function(obj){
    var stuff = '';
    for (var i in obj){
        stuff=stuff+obj[i].route;
        stuff+='\n';
    }
    return stuff;
}

var triggerEvent = function(targetid){
    console.log(targetid);
    $(document).trigger('eeeevent',targetid);
};

var obj = {myname:'Hans Fast'};

var resOlve = function (target, content){
    var dfd = $.Deferred();
    dfd.done(function(that){
        console.log('this is cool');
        console.log(that.target);
        console.log(this.myname);
        
    });
    target.html(content).promise().done(function(){console.log(this);$(document).trigger('rendered',{target:target,that:obj});console.log('object is:');console.log(obj)});
    //dfd.resolveWith(obj,[{myname:'Peter Fast',target:target}]);
}

makeMap = function(event, data){
    var target = data.target;
    var context = data.that;
    var targetid = $(target).attr('id');
     this.map = new L.Map(targetid, {zoomControl: false, attributionControl: false}).setView([-5.07, 18.79], 6);
    //big block of stuff for displaying and attributing background map
    var mapQuestAttr = 'Tiles Courtesy of <a href="http://www.mapquest.com/">MapQuest</a> &mdash; ';
    var osmDataAttr = 'Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
    var mopt = {
    url: 'http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpeg',
    options: {subdomains:'1234'}
    };
    var osm = L.tileLayer("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{attribution:osmDataAttr});
    var mq=L.tileLayer(mopt.url,mopt.options);
    mq.addTo(this.map);
};
$(document).ready(function($){
    
    $(document).on('rendered',makeMap);
    var tmpl = $.templates('#mainTmpl');
    var tmpl2 = $.templates('#monthTmpl');
    var html = tmpl.render(testdata, {getFields: getFields,doSomething:doSomething,triggerEvent:triggerEvent});
    resOlve($('#testdiv'), html);
    //$('#testdiv').html(html).promise().done(function(){makeMap(this)});;
});