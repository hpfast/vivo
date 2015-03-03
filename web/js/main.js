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
            $(data.container).trigger('request-routes',data.value);
        }   
    }

    self.prepareRoutesRequest = function(event,data){
        event.preventDefault();
        var context = event.data || event.target;
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
    this.layers = []; //to save a reference to layers we add to the map, for event hooks
    this.uuid = app.UUID.generate();
    this.tmpl = $.templates('#mainTmpl');
    this.html = this.tmpl.render(app.testdata);
    this.ourcontainer = $('<div id="'+this.uuid+'"  class="container">');
    this.dataFetcher = new app.DataFetcher(this.ourcontainer, this);
    this.ourcontainer.html(this.html)
    parent_target.append(this.ourcontainer);
    //setter function that triggers an event when routes are added
    this.addRoutes = function(data, context){
        //console.log('addRoutesSetter')
        context.routes = data;
        $(context.ourcontainer).trigger('routesadded',context);
    };
    $(app).trigger('container-created',
                   {container:this.ourcontainer,context:that}
    );
    //this could be a generalized function that just appends the div, renders the given template,
    //and sets the resulting html as the content of the template, then triggering another custom event.
    this.resOlve = function(targetdiv, container, data, template){
        //console.log('resOlve')
        var that = this;
        var dfd = $.Deferred();
        var tmpl = $.templates(template);
        var findParent = function(){$(this).parent()};
        //var html = tmpl.render(data,{findParent:findParent});
        var uuid = app.UUID.generate();
        //var ourdiv = $('<div id="'+uuid+'">').appendTo(targetdiv);
        var ourdiv = $(tmpl.render(data,{findParent:findParent}));
        //ourdiv.html(html).promise().done(function(){
        targetdiv.append(ourdiv).promise().done(function(){
        $(container).trigger(template+'-added', {d:data,that:that,self:ourdiv});//this
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
    $(d.container).on('request-routes',d.context,app.controls.prepareRoutesRequest);
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
    $(d.container).on('#runTmpl-added',app.solutionBuilder);
    $(d.container).on('#solTmpl-added',app.monthBuilder);
    $(d.container).on('#monthTmpl-added',app.mapBackgroundBuilder);
    $(d.container).on('background-layers-added',app.mapForegroudBuilder);
    $(d.container).on('routesready', app.drawRoutes);
    $(d.container).trigger('request-routes','Latest');
    $(d.container).on('routes-drawn',app.addRoutesToList);
    $(d.container).on('#routeListTmpl-added', app.addRouteListListeners);
};

//constructor to create a pane with Leaflet map and proper data bindings
app.Map = function (mapdivid,data) {
    this.data = data;
    this.map = new L.Map(mapdivid,
                         {zoomControl: false,
                          attributionControl: false
                         }
                        ).setView([-4.91, 18.79], 7);
    this.data.that.maps.push(this);                
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
    
    // Jan 2015: For now, hiding map tiles to declutter look
    //mq.addTo(this.map);
    
    this.mapid = mapdivid;
    
    var that = this;
    this.labeller = function(feature, layer) {
        var themap = that.map;
        
        //method with leaflet.label, strange results
//        var label = new L.Label({noHide: true, zoomAnimation:false,pane:'popupPane'});
//        label.setContent(feature.properties.name);
//        label.setLatLng(layer.getBounds().getCenter());
//        themap.showLabel(label);
    
        var point = layer.getBounds().getCenter();
        var myDivIcon = L.divIcon({
            className: 'my-div-icon',
            html:feature.properties.name
        });
        L.marker(point, {icon: myDivIcon}).addTo(themap);
        
    }
    
    app.hzlayer = L.geoJson(null, {
        style: function(feature){
            return {
                color:'#333',
                weight: 1,
                opacity: 0.2,
                fillOpacity:'0'
            };
        },
        onEachFeature: this.labeller
    })
    
        var geojsonMarkerOptions = {
        radius: 2,
        fillColor: "#fff",
        color: "#333",
        weight: 1,
        opacity: 1,
        fillOpacity: 0.8
    };
    
    var myIcon = L.icon({
        iconUrl: 'hospital.png',
        iconSize: [20,20],
        iconAnchor: [15, 15],
        labelAnchor: [15, 15] // as I want the label to appear 2px past the icon (10 + 2 - 6)
    });
    
    var myDivIcon = L.divIcon({
        className: 'my-div-icon',
        html:'some text'
    });
    
    app.hslayer = L.geoJson(null, {
         pointToLayer: function(feature, latlng){
           var myDivIcon2 = L.divIcon({
             className: 'my-div-icon',
             html: feature.properties.name + ' (' + feature.properties.hz_id.toString() + ')'
            });

           var myDivIcon2 = L.divIcon({
             className: 'my-div-icon',
             html: feature.properties.hz_id.toString()
            });

            //var marker = new L.marker(latlng,{icon:myIcon});
            var marker = new L.marker(latlng,{noHide:true, icon:myDivIcon2 });
            
            marker.bindLabel(
                //feature.properties.hz_id.toString(),{className:'label'}
                feature.properties.name,{className:'label'}
                );
            return(marker);

             //return L.circleMarker(latlng,geojsonMarkerOptions)
             //return L.marker(latlng,{icon:myDivIcon});
             //return L.marker(latlng,{icon:myIcon})
            // .bindLabel(feature.properties.hz_id.toString(),{zoomAnimation:false,noHide:true,pane:'popupPane',direction:'auto'}).bindPopup(feature.properties.hz_id.toString());
        }


//        ,
//        onEachFeature: function(feature,layer){
//            var label = new L.Label();
//            var ltlng = layer.getLatLng();
//            label.labelAnchor = ltlng;
//            layer.bindLabel(feature.properties.hz_id.toString(),{noHide:true});
//        }
    });
    
    var dfd = $.Deferred();
    
    this.triggerEvents = function(){
        //console.log("triggerevents")
        $(this.data.that.ourcontainer).trigger('background-layers-added',this.data);
    };
    
    this.map.addEventListener('layeradd',function(event){
        if(event.layer == app.hzlayer){
            this.addnextlayer();
        }else if (event.layer == app.hslayer){
            this.map.removeEventListener('layeradd');
            this.triggerEvents();
           // $(this.data.that.ourcontainer).trigger('background-layers-added',this.data);
        }
    },this);
    
    this.addnextlayer = function(){
        //console.log("addnextlayer")
        omnivore.geojson('data/hosps-bandundu.geojson',null,app.hslayer)
        .on('ready', function(){$(app).trigger('ok')})
        .addTo(this.map).bringToFront();    
    };
    
    
    
    
    omnivore.geojson('data/hz-test.geojson',null,app.hzlayer)
    .addTo(this.map);

    
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

//draw all routes
app.drawRoutes = function(event, data){
    //console.log('drawRoutes')
    var routes = data.routes;
    for (var i=0; i<routes.length;i++){
        app.drawRoute(null,{'that':data.that,'route':routes[i],'mapid':data.mapid, 'route_index': i}); 
    }
    $(data.that.ourcontainer).trigger('routes-drawn', {mapid:data.mapid,that:data.that,routes:routes});

}

//get the route, look up the points by hosp id and make a line and add it to the map
app.drawRoute = function(event, data){
    //console.log('drawRoute')
    var colorhex = '#' + (Math.random().toFixed(6).toString(16)).slice(2);
    //console.log(event);
    //console.log(data.route.sol_id);
    var results = app.getObjects(data.that.routes,'route_id',data.route.route_id, 'route');
    var pickup_node = app.getObjects(data.that.routes,'route_id',data.route.route_id, 'pickup')[0]
    var dropoff_node = app.getObjects(data.that.routes,'route_id',data.route.route_id, 'dropoff')[0];

    var route = results[0]; //just one for now
    //we need to draw the polylines and draw the points separately
    // var latlngs = [];
    // //always start at 223
    // if (route[0] != '223'){
    //     route.unshift('223');
    // };

    // for (var i in route){
    //     var c = app.getCoords(app.geodata.hospitals.features,route[i]);
    //     latlngs.push(L.latLng(c[1],c[0]));
    // }

    // var polyline = L.polyline(latlngs, {color: colorhex})
    //   polyline.addLatLng(app.geodata.kikwit)
    //   polyline.bindPopup(data.route.route_id+': '+route); //add the depot


    mylines = [];
    var supervisionleg=false;
    for (i = 0; i < route.length-1; i++) {
      var latlngs = [];
      var c = app.getCoords(app.geodata.hospitals.features,route[i]);
      latlngs.push(L.latLng(c[1],c[0]));
      var c = app.getCoords(app.geodata.hospitals.features,route[i+1]);
      latlngs.push(L.latLng(c[1],c[0]));
      mymod = data.route_index % 4;
      routeclass = 'route' + data.route_index.toString() + " " + 'mod' + mymod.toString();

        var myIcon = L.icon({
            iconUrl: 'hospital.png',
            iconSize: [20,20],
            iconAnchor: [15, 15],
            labelAnchor: [15, 15] // as I want the label to appear 2px past the icon (10 + 2 - 6)
        });


      if (route[i]==pickup_node) {
        supervisionleg=true;
        //console.log(latlngs)
        var marker = new L.marker(latlngs[0],{icon:myIcon});
        //mylines.push(marker);
      }
      if (route[i]==dropoff_node) {
        supervisionleg=false;
      }
      if (supervisionleg) {
        myclass = "Leg SupervisionLeg " + routeclass;
        //var polyline = L.polyline(latlngs, {color: colorhex, className: myclass})
        var polyline = L.polyline(latlngs, {className: myclass});
        //polyline.addLatLng(app.geodata.kikwit)
        //polyline.bindPopup(data.route.route_id+': '+route);
        //console.log( route[i], route[i+1])
        mylines.push(polyline);
        myclass = "Leg OtherLegs " + routeclass;
        var polyline = L.polyline(latlngs, {className: myclass});
        //var polyline = L.polyline(latlngs, {color: colorhex, className: myclass})
        //polyline.addLatLng(app.geodata.kikwit)
        //polyline.bindPopup(data.route.route_id+': '+route);
        //console.log( route[i], route[i+1])
        mylines.push(polyline);
      }
      else {
        myclass = "Leg OtherLegs " + routeclass;
        //console.log(myclass)
        var polyline = L.polyline(latlngs, {className: myclass})
        //polyline.addLatLng(app.geodata.kikwit)
        //polyline.bindPopup(data.route.route_id+': '+route);
        //console.log( route[i], route[i+1])
        mylines.push(polyline);
      }

    }

    var fg = L.featureGroup(mylines)
        .bindPopup('Hello world!')
        .on('mouseover', function() {
        })
   
    //save reference to layer!
    data.that.layers.push({
        route_id:data.route.route_id,
        layer:fg // was polyline previously
    });


    var ourmap = app.getMap(data.that.maps, 'mapid', data.mapid);
    //ourmap.map.addLayer(polyline);
    $(app).on('ok',ourmap,function(event){
      //polyline.addTo(event.data.map).bringToFront();
      fg.addTo(event.data.map).bringToFront();
      if (marker) {
        marker.addTo(event.data.map) //.bringToFront();
      } 
      $('.FirstLeg, .SupervisionLeg')
        //.css({'stroke-dasharray':'5,5', 'stroke-width': '2px', 'color': 'red'})
        .removeAttr('stroke-width')
        .removeAttr('stroke')
        .removeAttr('stroke-opacity')
        //.removeAttr('stroke-linejoin')
        .removeAttr('stroke-linecap')
    })
}


app.addRoutesToList = function(event, data) {
    //console.log("addroutestolist")
    var ourmap = app.getMap(data.that.maps, 'mapid', data.mapid);
    var mapcontainer = ourmap.map._container;
    var listcontainer = $('<div class="route-list" id="list-'+data.mapid+'">');
    $(mapcontainer).after(listcontainer);
    var ourroutes = [];
    for (var i=0;i<data.routes.length;i++){
        ourroutes.push(app.formatRouteForList(data.routes[i]));
    };
    // ourroutes.sort(function(a,b){
    //     return a.order - b.order;
    // });
    data.that.resOlve(listcontainer,data.that.ourcontainer,ourroutes,'#routeListTmpl');
  
}

//parse the route object to add hooks for styling the node types
app.formatRouteForList = function(route){
    //console.log(route);
    //console.log("formatrouteforlist")
    var out = {};
    out.id = route.route_id;
    out.cost = route.route.cost;
    out.order = route.route_order;
    out.trip = route.trip;
    out.route = [];
    var med = route.med
      .replace(/{/, '').replace(/}/, '').split(',');
    for (var i=0;i<route.route.length;i++){
        var it = route.route[i];
        var newroute = {};
        newroute.node = it;
        if (med.indexOf(it) != -1) {
            newroute.med = true;
        };
        if (route.pickup && route.pickup == it){
            newroute.pickup = true;
        };
        if (route.dropoff && route.dropoff == it){
            newroute.dropoff = true;
        };
        out.route.push(newroute);
    }
    return out;
};

app.addRouteListListeners = function(event, data){
    //console.log("addroutelisteners")
    data.self.on('mouseover',data,function(event){
        var routeid = event.currentTarget.getAttribute('data-id');
        //console.log('we hovered over '+routeid);
        //targetlayer.originalStyle = targetlayer.layer.options;
        //targetlayer.layer.setStyle({weight:10,color:'#ff9306'});
        var featuregroup = app.getMap(event.data.that.layers,'route_id',routeid);//reuse getMap because it returns a single item from an array
        //console.log(featuregroup)
        $('path').addClass('lowlight');
        featuregroup.layer.eachLayer( function(layer) {
            test = L.DomUtil.get(layer);
            temp = $(test._path);
            //console.log(temp)
            //temp.addClass('hello');
            //$('.route10').removeClass('highlight')
            temp.removeClass('lowlight');
            temp.addClass('highlight').show();
        })
            
    }).on('mouseout',data,function(event){
        var routeid = event.currentTarget.getAttribute('data-id');
        var featuregroup = app.getMap(event.data.that.layers,'route_id',routeid);
        featuregroup.layer.eachLayer( function(layer) {
            test = L.DomUtil.get(layer);
            temp = $(test._path);
            //console.log(temp)
            //temp.addClass('hello');
            //$('.route10').removeClass('highlight')
            temp.removeClass('highlight');
        })
        $('path').removeClass('lowlight');

        //targetlayer.layer.setStyle(targetlayer.originalStyle);
        
    });
}

app.runBuilder = function(event, data){
    //first loop:
    //console.log("runbuilder")
    for (var i in data.routes){
        var wrapper= $(data.ourcontainer).find('.map-wrapper');
        var uuid = app.UUID.generate();
        data.resOlve(wrapper,data.ourcontainer,data.routes[i], '#runTmpl');
    }
       
    
}

app.solutionBuilder = function(event, data){
    //console.log("solutionbuilder")
    var that = data.that;
    for (var i=0;i<data.d.data.length;i++){
        data.that.resOlve($(data.self),//.find('.run-wrapper'),
                          that.ourcontainer,data.d.data[i], '#solTmpl');
    }
}


app.monthBuilder = function(event, data){
    //console.log("monthbuilder")
    var that = data.that;
    var months = data.d.months;
    for (var i = 0; i < months.length; i++) {
        data.that.resOlve($(data.self).find('.pure-u-md-7-8'),//.find('.sol-wrapper'),
                          that.ourcontainer,{sol_id:data.d.sol_id,month:months[i],container_id:that.uuid}, '#monthTmpl');   
    }
    
}

app.mapBackgroundBuilder = function (event, data) {
    //console.log("mpbackgroundbuilder")
    var that = data.that;
    var mapdivid = data.that.uuid+'-map-'+data.d.sol_id+'-'+data.d.month.id;
    //that.maps.push(new app.Map(mapdivid,data));//app.Map will take care of triggering next event
    var map = new app.Map(mapdivid,data);
    //that.maps.push(map);
    
}

app.mapForegroudBuilder = function(event, data) {
    //console.log("mpforegroundbuilder")
    var that = data.that;
    var routes = data.d.month.data;
    var mapdivid = that.uuid+'-map-'+data.d.sol_id+'-'+data.d.month.id;
    for (var i = 0; i<routes.length;i++){ 
            var route = routes[i];
            route.route = route.nodes
              .replace(/{/, '').replace(/}/, '').split(',');
    }
    $(that.ourcontainer).trigger('routesready',{that:that, routes:routes, mapid:mapdivid});
    $(that.ourcontainer).trigger('mapsadded');
    
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

app.DataFetcher = function(context, container){
    var context = context;
    this.fetchData = function(url){
        //quickfix: kill container's maps and layers from here (should do it somewhere else)
        container.maps = [];
        container.layers = [];
        container.routes = {};
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
            //console.log(statusText,jqXHR);
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
    $(app).on('geodataparsed',function(event,data){
        app.containers.push(new app.Container($('.group-wrapper')));
    });
    $(app).on('geodatafetched',function(event,data){
        app.geodata.hospitals = JSON.parse(data);
        $(app).trigger('geodataparsed');
    });
    $(app).on('selector-clicked',app.controls.selectDetector);
    //general listener for all selects. We'll detect which container it targets
    $(document).on('change', 'select', function(e){
        $(app).trigger('selector-clicked',e)
    }); 
    
    $(app).on('container-created',app.setUpSelectListeners);
    
    //On page load, make a new container in the group container div

    
    $.ajax({
        type: 'GET',
        url: 'data/hospitals.geojson',
        datatype: 'json'
    }).done(function(data,statusText,jqXHR){
        $(app).trigger('geodatafetched',data)
    }); 
});;