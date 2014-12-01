//500 lines?
var app = app || {}, opp = {};

/**
 * Fast UUID generator, RFC4122 version 4 compliant.
 * @author Jeff Ward (jcward.com).
 * @license MIT license
 * @link http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/21963136#21963136
 **/
app.UUID = (function() {
  var self = {};
  var lut = []; for (var i=0; i<256; i++) { lut[i] = (i<16?'0':'')+(i).toString(16); }
  self.generate = function() {
    var d0 = Math.random()*0xffffffff|0;
    var d1 = Math.random()*0xffffffff|0;
    var d2 = Math.random()*0xffffffff|0;
    var d3 = Math.random()*0xffffffff|0;
    return lut[d0&0xff]+lut[d0>>8&0xff]+lut[d0>>16&0xff]+lut[d0>>24&0xff]+'-'+
      lut[d1&0xff]+lut[d1>>8&0xff]+'-'+lut[d1>>16&0x0f|0x40]+lut[d1>>24&0xff]+'-'+
      lut[d2&0x3f|0x80]+lut[d2>>8&0xff]+'-'+lut[d2>>16&0xff]+lut[d2>>24&0xff]+
      lut[d3&0xff]+lut[d3>>8&0xff]+lut[d3>>16&0xff]+lut[d3>>24&0xff];
  }
  return self;
})();

app.templates = {};
app.templates.run = $.templates('#runTmpl');
app.templates.sol = $.templates('#solTmpl');
app.templates.month = $.templates('#monthTmpl');

app.geodata = {};
app.geodata.kikwit = L.latLng(-5.021301252987202,18.824065464564228);

//create controls as a 'module' like UUID
app.controls = (function() {
    self = {};
    self.selectDetector = function (event, e) {
        e.preventDefault();
        var t;
        for (var i in e.target.children){
            if (e.target.children[i].selected){
                t = e.target.children[i].value;
                //trigger it on
                var target = $(e.target).closest('.container');
                target.trigger('select-option-chosen',
                               {container:target,target:e.target,value:t}
                );
            }
        }
    };

    //show and prime a route selector control
    self.switchSelectorControl = function(event, data){
        if (data.value != 'Latest'){
            $(data.target).siblings('form').css('display','inline')
              .find('input').val(data.value).attr('data-type',data.value);
        } else if (data.value == 'Latest'){
            $(data.target).siblings('form').css('display','none')
              .find('input').val(data.value).attr('data-type',data.value);
            $(app).trigger('request-routes',data.value);
        }   
    }

    self.prepareRoutesRequest = function(event,data){
        event.preventDefault();
        var context = event.data;
        function composeUrl(val){
            if (val == 'Latest'){
                return('/routes/byrun/latest');
            } else if (val == 'Select run'){
                return('/routes/byrun/')
            } else if (val == 'Select solution'){
                return('/routes/bysolution/')
            } else if (val == 'Select individual route') {
                return('/routes/byid/')
            }
        }
        //form submit
        if (event.type == 'submit') {
            event.preventDefault();
            endpoint = event.target[0].value;
            route = $(event.target[0]).attr('data-type');
            context.dataFetcher.fetchData(
                app.conf.base_url+composeUrl(route)+endpoint
            );

        //select 'latest'
        } else if (event.type='request-routes') {
            context.dataFetcher.fetchData(
                app.conf.base_url+composeUrl(data)
            );
        }
        return false;
    }
    return self;
})();


app.containers = [];

//create a container obj with link to new rendered container div
app.Container = function(parent_target) {
    var that = this;
    this.routes = {};
    this.maps = [];
    this.uuid = app.UUID.generate();
    this.tmpl = $.templates('#mainTmpl');
    this.html = this.tmpl.render(app.testdata);
    this.ourcontainer = $('<div id="'+this.uuid+'"  class="container">');
    this.dataFetcher = new app.DataFetcher(this.ourcontainer);
    this.ourcontainer.html(this.html)
    parent_target.append(this.ourcontainer);
    //setter function that triggers an event when routes are added
    this.addRoutes = function(data, context){
        context.routes = data;
        $(context.ourcontainer).trigger('routesadded',context);
    };
    $(app).trigger('container-created',
                   {container:this.ourcontainer,context:that}
    );
    //this could be a generalized function that just appends the div, renders the given template,
    //and sets the resulting html as the content of the template, then triggering another custom event.
    this.resOlve = function(targetdiv, container, data, template){
        var that = that;
        var dfd = $.Deferred();
        var tmpl = $.templates('#runTmpl');
        var html = tmpl.render(data);
        var ourdiv = $('<div id="boooh">').appendTo(targetdiv);
        ourdiv.html(html).promise().done(function(){
            var that = this;
            $(container).trigger(template+'-added', {d:data,that:that});
        });
    }
    
}

//In the end, we want to call our map drawing routines with the right map as the target.
// first, we then want to add leaflet map to each one.
// so maybe the approach to take: build up the DOM elements first, and as each month div is completed, call a 'leaflet-initialization' function with that div as the target.
//we want to 
            
            
//we set up listeners for the route selector controls,
//binding them to the container in question
app.setUpSelectListeners = function(event, d){
    $(d.container).on('request-routes',app.controls.prepareRoutesRequest);
    $(d.container).find('form.select-input').on(
        'submit',
        d.context,
        app.controls.prepareRoutesRequest
    );
    $(d.container).on('select-option-chosen',app.controls.switchSelectorControl);
    $(d.container).on('click','.close-container',function(e){
        app.destroyContainer(e)
    });
    //pass context to groupRoutes so it 
    $(d.container).on('datafetched', function(event, data){
        app.groupRoutes(event,data,d.context,d.context.addRoutes);
    });
    $(d.container).on('routesadded',function(event,data){
        $(data.ourcontainer).find('.map-wrapper').empty();
        app.runBuilder(event,data);
    });
    $(d.container).on('run-added',app.solutionBuilder);
};

//constructor to create a pane with Leaflet map and proper data bindings
app.Map = function (data, target,i) { //temporary solution: distinguish with solution id.
    var id = $(target).attr('id')+'-'+i;
    $(target).append($('<div id="'+id+'-box" class="map-box"><div id="'+id+'-map" class="map"></div>'));
    this.map = new L.Map(id+'-map',
                         {zoomControl: false,
                          attributionControl: false
                         }
                        ).setView([-5.07, 18.79], 6);
    //big block of stuff for displaying and attributing background map
    var mapQuestAttr = 'Tiles Courtesy of <a href="http://www.mapquest.com/">MapQuest</a> &mdash; ';
    var osmDataAttr = 'Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
    var mopt = {
    url: 'http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpeg',
    options: {subdomains:'1234'}
    };
    var osm = L.tileLayer("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          {attribution:osmDataAttr}
                         );
    var mq=L.tileLayer(mopt.url,mopt.options);
    mq.addTo(this.map);
    $('#'+id+'-map').before($('<h3>Month '+i+'</h3>'));

    
    
};
//need to reparse the nice hierarchical data structure for jsrender :(
//app.runBuilder = function(event, data){
//    for (var i in data.routes){
//        var wrapper = $(data.ourcontainer).find('.map-wrapper');
//        var uuid = app.UUID.generate()
//        var runtarget = $('<div id="run-'+data.routes[i].run_id+'-'+uuid+'">')
//          .appendTo(wrapper);
//        runtarget.append('<h1>Run '+data.routes[i].run_id+'</h1>');
//        for (var j in data.routes[i].data){
//            var sol = data.routes[i].data[j];
//            var target = $('<div id="sol-'+sol.sol_id+'">')
//              .appendTo($(runtarget));
//            $(target).append('<h2>Solution '+sol.sol_id+'</h2>');
//                var month_count = sol.months.length;
//                for (var i = 0; i<month_count;i++){ 
//                    data.maps.push(new app.Map(data,target,i));
//                    for (var o = 0; o<sol.month[i].length;o++){ 
//                        sol.month[i][o].route = sol.month[i][o].route
//                          .replace(/{/, '').replace(/}/, '').split(',');
//                        $(app).trigger('mapready',
//                                       {route_id: sol.month[i][o].route_id,
//                                        sol_id: sol.month[i][o].sol_id
//                                        }
//                        );
//                    }
//
//                }
//                $(app).trigger('mapsadded');
//
//            }
//        }
//    
//}

app.runBuilder = function(event, data){
    //first loop:
    for (var i in data.routes){
        var wrapper= $(data.ourcontainer).find('.map-wrapper');
        var uuid = app.UUID.generate();
        data.resOlve(wrapper,data.ourcontainer,data.routes[i], 'run');
    }
       
    
}

app.solutionBuilder = function(event, data){
    console.log("let's see what THIS is ... ");
    console.log(data.that);
    for (var i=0;i<data.d.data.length;i++){
        console.log(data.d.data[i]);
    }
}
    

app.mapBuilder = function (event, data) {
    var month_count = data.months.length;
    for (var i = 0; i<month_count;i++){ 
        app.maps.push(new app.Map(i, routes_by_month[i][0].sol_id));
        for (var o = 0; o<routes_by_month[i].length;o++){ 
            routes_by_month[i][o].route = routes_by_month[i][o].route
              .replace(/{/, '').replace(/}/, '').split(',');
            $(app).trigger('mapready',
                           {route_id: routes_by_month[i][o].route_id
                            ,sol_id: routes_by_month[i][o].sol_id
                           }
            );
        }
    }
    $(app).trigger('mapsadded');
}

app.destroyContainer = function(event){
    target = event.delegateTarget;
    var id = $(target).attr('id');
    app.tearDownListeners(target);
    $(target).remove();
    var index;
    for (var i=0;i<app.containers.length;i++){
        if (app.containers[i].uuid == id){
            index = i;
            break;
        }
    };
    app.containers.splice(index,1);
};

app.tearDownListeners = function(container){
    //don't know if this actually is necessary if we destroy the whole object.
    //or do remaining references via listeners keep container from being GC'd?
    //in that case need to remove the other ones as well ...
    $(container).off({keys:'request-routes select-option-chosen click'});   
}

app.DataFetcher = function(context){
    var context = context;
    this.fetchData = function(url){
        $.ajax({
            type: 'GET',
            url: url,
            dataType: 'json'
        })
          .done(function(data,statusText,jqXHR){
            //pass on data and request endpoint type
            $(context).trigger('datafetched',{
                d:data,
                r:this.url.match('/routes/(.*)/')[1]
              });
        })
          .fail(function(data,statusText,jqXHR){
            console.log(statusText,jqXHR);
        }); 
    }
};


//learned this on http://codereview.stackexchange.com/questions/37028/grouping-elements-in-array-by-multiple-properties
//modified to create an array of named objects rather than of arrays
app.groupBy = function ( array , f, type) {
      var groups = {};
      var group_id = '';
      array.forEach( function( o )
      {
        var group = JSON.stringify( f(o) );
        group_id = group;
        groups[group] = groups[group] || [];
        groups[group].push( o );  
       // groups.push( o );
      });
    if (type && type == 'object'){
        return groups;
    } else if (type && type == 'array'){
        //enable below instead to return arrays
      return Object.keys(groups).map( function( group )
      {
        return {id: group, data: groups[group]}; 
      })
    }
}

//group by month, solution, and run.
//if passed context and callback, executes callback with context.
//else returns grouped data.
app.groupRoutes = function(event, data, context, callback){
    var data_grouped = [];
    var temp_sol = [];
    var temp_mo = [];
    var by_run = app.groupBy(data.d, function(item){return item.run_id}, 'array');
    for (var i=0;i<by_run.length;i++){// in by_run){
        temp_sol[i] = app.groupBy(by_run[i].data, function(item){
            return item.sol_id}
            , 'array');
        data_grouped[i] = {};
        data_grouped[i].run_id = by_run[i].id;
        data_grouped[i].data = [];
       // for (var j=0;j<temp_sol[i].length;j++){
        for (var j in temp_sol[i]){
            data_grouped[i].data[j] = {};
            data_grouped[i].data[j].sol_id = temp_sol[i][j].id;
            // data_grouped[i].data[j].months = [];
            data_grouped[i].data[j].months = app.groupBy(temp_sol[i][j].data,
                                        function(item){return item.month},
                                        'array');
        }
    }
    if (context && callback) {
        //context.addRoutes(data_grouped); //only semi-encapsulated ...
        callback(data_grouped,context);    //slightly better ...
        return true;
    } else {
        return data_grouped;
    }
    //console.log(data_grouped);       
};

$(document).ready(function($){
    app.conf = custom_config || {};
    $(document).on('click','#new-container-button',function(e){
        app.containers.push(new app.Container($('.group-wrapper')));
    });
        //two handlers for preparing routes request
   // $(app).on('request-routes',app.prepareRoutesRequest);
   // $('form.select-input').on('submit',app.prepareRoutesRequest);
    
    $(app).on('selector-clicked',app.controls.selectDetector);
    //general listener for all selects. We'll detect which container it targets
    $(document).on('change', 'select', function(e){
        $(app).trigger('selector-clicked',e)
    }); 
    
    $(app).on('container-created',app.setUpSelectListeners);
    
    //On page load, make a new container in the group container div
    app.containers.push(new app.Container($('.group-wrapper')));
    
});