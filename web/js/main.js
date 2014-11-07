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
    var map = new L.Map('map'+num).setView([-5.07, 18.79], 6);
    //big block of stuff for displaying and attributing background map
    var mapQuestAttr = 'Tiles Courtesy of <a href="http://www.mapquest.com/">MapQuest</a> &mdash; ';
    var osmDataAttr = 'Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
    var mopt = {
    url: 'http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpeg',
    options: {attribution:mapQuestAttr + osmDataAttr, subdomains:'1234'}
    };
    var osm = L.tileLayer("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{attribution:osmDataAttr});
    var mq=L.tileLayer(mopt.url,mopt.options);
    mq.addTo(map);
    $('#map'+num).before($('<h2>Month '+num+'</h2>'));

    
    
};

//wrapper function calls app.Map constructor on 'datafetched' event
app.mapBuilder = function (event, data) {
    for (var i = 0; i<data.d.length;i++){
        app.maps.push(new app.Map(i+1));
    }   
    
}


app.maps = [];

var testobj = [1,2,3];

$(document).ready(function ($) {
    
    $(app).on('datafetched',app.mapBuilder)
    
    var request = {"sql":""};
    
    //TODO: instead of seed.json, query the database.
    $.ajax({
        //type: 'POST',
        type: 'GET',
        //url: 'data/seed.json',
       url:'http://128.199.53.137:8080/routes/10',
        // url: 'http://192.168.122.116:3000/db/postgres/schemas/public/tables/',
        //data: request,
        dataType: 'json'
    }).done(function(data,statusText,jqXHR){
        console.log('do we get this far?');
        console.log(data);
        $(app).trigger('datafetched',{d:data});
        
    }).fail(function(data,statusText,jqXHR){
        console.log(statusText,jqXHR);
    });
    

    
});