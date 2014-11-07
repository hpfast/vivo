var app = app || {};

//constructor to create a pane with Leaflet map and proper data bindings
app.Map = function (num) {
    var time = new Date();
    var num = num;
    this.name = function(){
        return(num)
    };
    this.whattime = function(){
        return(time)
    };
    $('#map-container').append($('<div id="map'+num+'-box" class="map-box"><div id="map'+num+'" class="map"></div>'));
    this.map = new L.Map('map'+num, {zoomControl: false, attributionControl: false}).setView([-5.07, 18.79], 6);
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
    $('#map'+num).before($('<h2>Map '+num+'</h2>'));

    
    
};

//wrapper function calls app.Map constructor on 'datafetched' event
app.mapBuilder = function (event, data) {
    for (var i = 0; i<data.d.length;i++){
        data.d[i].route = data.d[i].route.replace(/{/, '').replace(/}/, '').split(',');
        app.maps.push(new app.Map(i+1));
        $(app).trigger('mapready', {route_id: data.d[i].route_id,map_id: i});
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
    console.log(data.map_id);
    var results = app.getObjects(app.data,'route_id',data.route_id, 'route');
    var route = results[0]; //just one for now
    
    //we need to draw the polylines and draw the points separately
    
    var latlngs = [];
    for (var i in route){
        var c = app.getCoords(app.geodata.hospitals.features,route[i]);
        latlngs.push(L.latLng(c[1],c[0]));
    }
    var polyline = L.polyline(latlngs,{color: 'red'}).addLatLng(app.geodata.kikwit); //add the depot
    app.maps[data.map_id].map.addLayer(polyline);

}

app.dataFetcher = function(){
    $.ajax({
        //type: 'POST',
        type: 'GET',
        //url: 'data/seed.json',
       //url:'http://128.199.53.137:8080/routes/byid/1',
        url:'http://128.199.53.137:8080/routes/bysolution/25',
        // url: 'http://192.168.122.116:3000/db/postgres/schemas/public/tables/',
        //data: request,
        dataType: 'json'
    }).done(function(data,statusText,jqXHR){
        app.data=data;
        $(app).trigger('datafetched',{d:data});
        
    }).fail(function(data,statusText,jqXHR){
        console.log(statusText,jqXHR);
    });

    
    
}

$(document).ready(function ($) {
    
    //$(app).on('geodataparsed',app.addGeodata); //demo function: to test if the geojson works
    $(app).on('datafetched',app.mapBuilder);
    $(app).on('geodatafetched',function(event,data){
        app.geodata.hospitals = JSON.parse(data);
        $(app).trigger('geodataparsed');
        app.dataFetcher();
    });
    $(app).on('mapready', app.drawRoutes);
    
    //for postgresql-http-server
    var request = {"sql":""};
    
        
    $.ajax({
        type: 'GET',
        url: 'data/hospitals.geojson',
        datatype: 'json'
    }).done(function(data,statusText,jqXHR){
        $(app).trigger('geodatafetched',data)
    });

    //add attribution
    $(app).on('mapsadded', function(){
        $('#map-container').append($('<p style="float:left; font-size:12px">').html('Powered by <a href="http://leafletjs.com">Leaflet</a> -- Tiles Courtesy of <a href="http://www.mapquest.com/">MapQuest</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'));
    });

    
});