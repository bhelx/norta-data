// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

import socket from "./socket"

import L from "leaflet"

let ready = (fn) => {
  if (document.readyState != 'loading'){
    fn();
  } else {
    document.addEventListener('DOMContentLoaded', fn);
  }
}

let getRouteShape = (route, done) => {
  let request = new XMLHttpRequest()

  request.open('GET', '/api/routes/'+route, true)
  request.setRequestHeader('Accept', 'application/json')

  request.onload = () => {
    if (request.status >= 200 && request.status < 400) {
      done(null, JSON.parse(request.responseText))
    } else {
      done("error")
    }
  }

  request.onerror = () => {
    done("onerror")
  }

  request.send()
}

let routes = window.params.routes || ['11', '12']
let showStale = window.params.stale

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("vehicles:routes", {routes: routes})

let allMarkers = {};

channel.join()
  .receive("ok", resp => { console.log("Joined channel", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

let updateRoute = (route, vehicles) => {
  let markers = allMarkers[route] || []

  markers.forEach((m) => {
     map.removeLayer(m)
  })

  markers = []

  vehicles.forEach((v) => {
    v.datetime = Date.parse(v.time)
  })

  if (!showStale) {
    vehicles = vehicles.filter((v) => !v.stale)
  }

  vehicles.forEach((v) => {
    let loc = new L.LatLng(v.lat, v.lng)
    let marker = L.circleMarker(
        loc,
        {
          radius: 4,
          opacity: 1.0,
          fillOpacity: 0.6,
          fillColor: (v.stale ? '#f00' : '#05A2F1'),
          color: (v.stale ? '#f00' : '#05A2F1')
        }
      )

    let popup = L.popup()
     .setLatLng(loc)
     .setContent('<p>' + v.name + '</p>')

    marker.addTo(map);

    marker.bindPopup(popup)

    markers.push(marker);
  })

  allMarkers[route] = markers
}

channel.on("update", payload => {
  console.log(payload)
  if (payload.routes) {
    // TODO implement multiplexed?
  } else {
    updateRoute(payload.route, payload.vehicles)
  }
})

ready(() => {
  map = L.map('map');

  map.setView([29.951066, -90.071532], 13);

  L.tileLayer('http://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.{ext}', {
      attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      subdomains: 'abcd',
      minZoom: 12,
      maxZoom: 19,
      ext: 'png'
  }).addTo(map);

  let defaultStyle = {
    "weight": 3,
    "opacity": 0.7
  }

  routes.forEach((route) => {
    getRouteShape(route, (err, data) => {
      if (err) return console.log(err)

      let style = Object.assign(defaultStyle, data.properties.style);

      L.geoJson(data, {style: style}).addTo(map)
    })
  })

});
