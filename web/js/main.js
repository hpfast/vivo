var app = app || {};

//app.base_url = 'http://128.199.53.137:8080';
app.base_url = 'http://192.168.122.116:8080';
app.url = '/routes/byrun/latest';


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

app.testdata = {string:'very cool stuff!'};
//This creates a new container of maps given an API url.
app.Container = function(event,data) {
    //all our model and view will be grouped by container.
    //so generate a UUID for this container.
    data.uuid = app.UUID.generate();
    app.filterRoutes(null,data);
    this.tmpl = $.templates('#mainTmpl');
    this.html = this.tmpl.render(app.testdata);
    this.ourcontainer = $('<div id="'+data.uuid+'">');
    this.ourcontainer.promise().done(function(){$(app).trigger('done')});
    this.ourcontainer.html(this.html);
    console.log('catch');
    $('#testdiv').append(this.ourcontainer);
    
    this.destroy = function(member){
        delete this.member;
    }
        
    
}

app.createContainer = function(event, data) {
    event.target.data = data;
    app.newcontainer = new app.Container(event, data);   
}

////from af
//    var tmpl = $.templates('#hrchyTmpl');
//    var html = tmpl.render(app.mydata, {foo:'hello',add: app.sumThings,sumtotal: app.sumTotal, format:app.formatNum,max:app.max,isNumeric:app.isNumeric,oneN:app.oneN,countDecimals:app.countDecimals});//lots of helper functions passed along.oneN: app.oneN
//    $("#content-container").html(html)
//        .promise().done(function(){$(app).trigger('done')
//    }); //register done event

//constructor to create a pane with Leaflet map and proper data bindings
app.Map = function (num, sol_id) { //temporary solution: distinguish with solution id.
    var time = new Date();
    var num = num;
    this.sol_id = sol_id;
    this.whattime = function(){
        return(time)
    };
    $('#map-container').append($('<div id="'+sol_id+'-map'+num+'-box" class="map-box"><div id="'+sol_id+'map'+num+'" class="map"></div>'));
    this.map = new L.Map(sol_id+'map'+num, {zoomControl: false, attributionControl: false}).setView([-5.07, 18.79], 6);
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
    $('#'+sol_id+'map'+num).before($('<h2>Map '+num+'</h2>'));

    
    
};

app.solutionBuilder = function(event, data){
    for (var i in data){
        $('#map-container').append('<h1>Solution'+i+'</h1>');
        app.mapBuilder(null,data[i]);
    };
    
}

//wrapper function calls app.Map constructor on 'datafetched' event
app.mapBuilder = function (event, data) {
    var routes_by_month = app.groupBy(data, function(item){return item.month});
    var month_count = Object.keys(routes_by_month).length;
    for (var i = 0; i<month_count;i++){ 
        app.maps.push(new app.Map(i, routes_by_month[i][0].sol_id));
        for (var o = 0; o<routes_by_month[i].length;o++){ 
            routes_by_month[i][o].route = routes_by_month[i][o].route.replace(/{/, '').replace(/}/, '').split(',');
            $(app).trigger('mapready', {route_id: routes_by_month[i][o].route_id,sol_id: routes_by_month[i][o].sol_id});
        }

    }
    $(app).trigger('mapsadded');
    
}

//return sel from obj where key equals val
app.getObjects = function(obj, key, val, sel) {
    var objects = [];
    for (var i in obj) {
        if (!obj.hasOwnProperty(i)) continue;
        if (typeof obj[i] == 'object') {
            objects = objects.concat(app.getObjects(obj[i], key, val,sel));
        } else if (i == key && obj[key] == val) {
            objects.push(obj[sel]);
        }
    }
    return objects;
};

app.getMap = function(obj, key, val){
    for (var i = 0; i<obj.length; i++) {
        if (obj[i][key] == val){
            return(obj[i]);
        }
    }
}; 

//making a custom query function for coordinates, because they're buried deep.
//might be cool to write a custom that could be plugged into the objects.push() statement in app.getObjects
app.getCoords = function(obj, val) {
    var objects = [];
    for (var i in obj) {
        if (obj[i].properties.hz_id == val){
            return(obj[i].geometry.coordinates);
        }
    }
};

app.maps = [];
app.geodata = {};
app.geodata.kikwit = L.latLng(-5.021301252987202,18.824065464564228);

//demo function: to test of the geojson works. Adds all hospitals to one of the maps.
app.addGeodata = function(){
    L.geoJson(app.geodata.hospitals, {onEachFeature: function (feature, layer) {
        layer.bindPopup(feature.properties.name);
    }
                                     }
             ).addTo(app.maps[0].map);
    
}

//get the route, look up the points by hosp id and make a line and add it to the map
app.drawRoutes = function(event, data){
    console.log(event);
    console.log(data.sol_id);
    var results = app.getObjects(app.data,'route_id',data.route_id, 'route');
    var route = results[0]; //just one for now
    
    //we need to draw the polylines and draw the points separately
    //TODO: group by solution, month etc
    var latlngs = [];
    for (var i in route){
        var c = app.getCoords(app.geodata.hospitals.features,route[i]);
        latlngs.push(L.latLng(c[1],c[0]));
    }
    var polyline = L.polyline(latlngs,{color: 'red'}).addLatLng(app.geodata.kikwit).bindPopup(data.route_id+': '+route); //add the depot
    var ourmap = app.getMap(app.maps, 'sol_id', data.sol_id);
    console.log(ourmap);
    ourmap.map.addLayer(polyline);

}

//viewer should handle all different kinds of API requests.
//decide which filter routines to call, end by triggering 'routesfiltered' with the data
//HOWEVER: what is handy for filtering?
app.filterRoutes = function(event, data){
    //check location string?
    // ...
    var data_filtered;
    if (data.r == 'byrun'){
        data_filtered = app.groupBySolution(null, data);
        app.group(null,data);
    }else{
        console.log('only testing byrun for now');
    }
    
    $(app).trigger('routesfiltered', data_filtered);
}

//learned this on http://codereview.stackexchange.com/questions/37028/grouping-elements-in-array-by-multiple-properties
//modified to create an array of named objects rather than of arrays
app.groupBy = function ( array , f, type) {
      var groups = {};
      array.forEach( function( o )
      {
        var group = JSON.stringify( f(o) );
        groups[group] = groups[group] || [];
        groups[group].push( o );  
      });
    if (type && type == 'object'){
        return groups;
    } else if (type && type == 'array'){
        //enable below instead to return arrays
      return Object.keys(groups).map( function( group )
      {
        return groups[group]; 
      })
    }

}


//should group by run, solution, and month.
app.groupBySolution = function(event, data){
    return(app.groupBy(data.d,function(item){
            return item.sol_id;
        })
    );
    
    
    
}

//group by month, solution, and run.
app.group = function(event, data){
    var data_grouped = {};
    var temp_sol = {};
    var by_run = app.groupBy(data.d, function(item){return item.run_id}, 'object');
    for (var i in by_run){
        temp_sol[i] = app.groupBy(by_run[i], function(item){return item.sol_id}, 'object');
        data_grouped[i] = {};
        for (var j in temp_sol[i]){
            data_grouped[i][j] = app.groupBy(temp_sol[i][j],function(item){return item.month}, 'object');
        }
    };
    console.log(data_grouped);    
        
        
        
}

//TODO: we need to group by month, count how many months there are, and draw that many maps,
//keeping track of map ids to put
app.groupByMonth = function(event, data){
    
    
}

app.dataFetcher = function(url){
    $.ajax({
        //type: 'POST',
        type: 'GET',
        //url: 'data/seed.json',
       //url:'http://128.199.53.137:8080/routes/byid/1',
        //TODO: get url from location bar or user input on page
        url: url,
        // url: 'http://192.168.122.116:3000/db/postgres/schemas/public/tables/',
        //data: request,
        dataType: 'json'
    }).done(function(data,statusText,jqXHR){
        app.data=data;
        
        //pass on data and request endpoint type
        $(app.testdata).trigger('datafetched',{d:data,r:this.url.match('/routes/(.*)/')[1]});
        
    }).fail(function(data,statusText,jqXHR){
        console.log(statusText,jqXHR);
    });

    
    
}

//encapsulate these as a module which can be run
app.selectDetector = function (event, e) {
    e.preventDefault();
    var t;
    for (var i in e.target.children){
        if (e.target.children[i].selected){
            t = e.target.children[i].value;
            $(app).trigger('select-option-chosen',{target:e.target,value:t});
        }
    }
};

//show and prime a route selector control
app.switchSelectorControl = function(event, data){
    if (data.value != 'Latest'){
    $(data.target).siblings('form').css('display','inline').find('input').val(data.value).attr('data-type',data.value);
    } else if (data.value == 'Latest'){
     $(data.target).siblings('form').css('display','none').find('input').val(data.value).attr('data-type',data.value);
        $(app).trigger('request-routes',data.value);
    }   
}

app.prepareRoutesRequest = function(event,data){
    
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
        app.dataFetcher(app.base_url+composeUrl(route)+endpoint);
    
    //select 'latest'
    } else if (event.type='request-routes') {
        app.dataFetcher(app.base_url+composeUrl(data));
    }
    return false;
}

$(document).ready(function ($) {
    
    //$(app).on('geodataparsed',app.addGeodata); //demo function: to test if the geojson works
    
    $(app).on('done',function(event,data){alert('this event fired!')});
    //TODO: before calling mapbuilder, run the grouping routines to end up with routes grouped by month.
    $(app.testdata).on('datafetched',app.createContainer);
    //$(app).on('datafetched',app.filterRoutes); //produces 'routesfiltered'
    $(app).on('routesfiltered',app.solutionBuilder);
    //$(app).on('datafetched',app.mapBuilder);
    $(app).on('geodatafetched',function(event,data){
        app.geodata.hospitals = JSON.parse(data);
        $(app).trigger('geodataparsed');
        app.dataFetcher(app.base_url+app.url);
    });
    $(app).on('mapready', app.drawRoutes);
    
    $(app).on('select-option-chosen', app.switchSelectorControl);
    
    //two handlers for preparing routes request
    $(app).on('request-routes',app.prepareRoutesRequest);
    $('form.select-input').on('submit',app.prepareRoutesRequest);
    $(app).on('selector-clicked',app.selectDetector);
    $(document).on('change', 'select', function(e){
        $(app).trigger('selector-clicked',e)
    }); 
    //for postgresql-http-server
    var request = {"sql":""};
    
        
    $.ajax({
        type: 'GET',
        url: 'data/hospitals.geojson',
        datatype: 'json'
    }).done(function(data,statusText,jqXHR){
        $(app).trigger('geodatafetched',data)
    });

    //add attribution for background map data
    $(app).on('mapsadded', function(){
        $('#map-container').append($('<p style="float:left; font-size:12px">').html('Powered by <a href="http://leafletjs.com">Leaflet</a> -- Tiles Courtesy of <a href="http://www.mapquest.com/">MapQuest</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'));
    });

    
});