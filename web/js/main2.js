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
                target.trigger('select-option-chosen',{container:target,target:e.target,value:t});
            }
        }
    };

    //show and prime a route selector control
    self.switchSelectorControl = function(event, data){
        if (data.value != 'Latest'){
        $(data.target).siblings('form').css('display','inline').find('input').val(data.value).attr('data-type',data.value);
        } else if (data.value == 'Latest'){
         $(data.target).siblings('form').css('display','none').find('input').val(data.value).attr('data-type',data.value);
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
            context.dataFetcher.fetchData(app.conf.base_url+composeUrl(route)+endpoint);

        //select 'latest'
        } else if (event.type='request-routes') {
            context.dataFetcher.fetchData(app.conf.base_url+composeUrl(data));
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
    $(app).trigger('container-created',{container:this.ourcontainer,context:that});
}

//we set up listeners for the route selector controls,
//binding them to the container in question
app.setUpSelectListeners = function(event, d){
    $(d.container).on('request-routes',app.controls.prepareRoutesRequest);
    $(d.container).find('form.select-input').on('submit',d.context,app.controls.prepareRoutesRequest);
    $(d.container).on('select-option-chosen',app.controls.switchSelectorControl);
    $(d.container).on('click','.close-container',function(e){
        app.destroyContainer(e)
    });
    //pass context to groupRoutes so it 
    $(d.container).on('datafetched', function(event, data){
        app.groupRoutes(event,data,d.context,d.context.addRoutes);
    });
    //$(d.container).on('routesadded',);
};

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

//group by month, solution, and run.
//if passed context and callback, executes callback with context.
//else returns grouped data.
app.groupRoutes = function(event, data, context, callback){
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