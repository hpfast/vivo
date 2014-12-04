============
Design notes
============

Currently I have a great framework for building up the hierarchical data framework, but it's a bit spaghetti-ish and data-specific. Meanwhile, I have a similar kind of 'framework' problem to solve for the Trouw app. Can I generalize?

My goal, however, is to get maps as soon as possible, so that I can start styling stuff. But this is an important problem to solve first, because I have the feeling we're going to be needing lots of flexibility for handling two-way data-binding later on.

but I need to be careful that I don't get bogged down. So what are the main goals?

Essentially I want an API to make hooking into (Leaflet) map data easier, for two-way data/display and map/rest-of-dom bindings. I dont' want to be rewriting these kinds of things all the time.

Taking into account possibility of using D3 map layers.

Study how bootleaf does it. But I don't want to use bootleaf, because that integrates the app and the template too tightly.

goal
====

You have a data source somewhere on the Internet. You want to show it to your users, and let your users interact with it.

Specifically, you have a variable number of maps you want to show. And you want to expose various ways for the user to interact with the mapped data: panning and zooming, selecting in a side panel, text search. You want some degree of interaction between side panel, search bar and map.

Leaflet has a great API for hacking, but after a while it gets tedious to rebuild the same event-based code for every application, especially if your apps reach some degree of complexity. The goal of this project is therefore a set of utility functions and data structures to make it easier to to the above tasks.

Makes extensive use of scoping and events.

Utility functions
-----------------

### app.DataFetcher({url: url, context: context}) -- constructor
get data from a (remote) source. Optional arguments are url and context.

###getKeys --