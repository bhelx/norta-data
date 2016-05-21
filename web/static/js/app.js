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
import React from "react"
import ReactDOM from "react-dom"
import socket from "./socket"
import L from "leaflet"

class Application {
  constructor(map, opts = {}) {
    this.map = map;
    this.currentRoutes = [];
    this.setCurrentRoutes(opts.routes || ['11', '12']);
    this.routeLayers = {};
    this.showStale = opts.state;
    this.markers = {};

    this.defaultRouteStyle = {
      "weight": 5,
      "opacity": 0.7
    }

    this.channel = socket.channel("vehicles:routes", {routes: this.currentRoutes})
    this.channel.join()
      .receive("ok", resp => { console.log("Joined channel", resp) })
      .receive("error", resp => {
        console.log("Unable to join", resp);
        alert("Unable to connect to channel");
      })

    this.channel.on("update", payload => {
      this.updateVehicles(payload.route, payload.vehicles);
    });
  }

  getCurrentRoutes() {
    return this.currentRoutes.slice(0);
  }

  setCurrentRoutes(newRoutes) {
    this.drawRoutes(newRoutes);
    this.currentRoutes = newRoutes;
  }

  drawRoutes(newRoutes) {
    let added = newRoutes.filter(i => this.currentRoutes.indexOf(i) < 0);
    let removed = this.currentRoutes.filter(i => newRoutes.indexOf(i) < 0);

    console.log('Removing Routes: ', removed);
    console.log('Adding Routes: ', added);

    // First remove any unsubscribed route layers
    removed.forEach(route => {
      this.map.removeLayer(this.routeLayers[route]);
      this.routeLayers[route] = null;
      // remove the vehicles too
      this.updateVehicles(route, []);
    });

    // Then add routes that didn't exist before
    added.forEach(route => {
      getRouteShape(route, (err, data) => {
        if (err) return console.log(err)

        let style = Object.assign(this.defaultRouteStyle, data.properties.style);
        let layer = L.geoJson(data, {style: style})

        layer.addTo(this.map)
        layer.bringToBack()

        this.routeLayers[route] = layer;
      })
    });
  }

  updateVehicles(route, vehicles) {
    let markers = this.markers[route] || [];

    markers.forEach(m => { this.map.removeLayer(m) });

    // vehicles.forEach(v => {
    //   v.datetime = Date.parse(v.time);
    // })

    if (!this.showStale) {
      vehicles = vehicles.filter((v) => !v.stale);
    }

    markers = vehicles.map(v => {
      let loc = new L.LatLng(v.lat, v.lng);
      let marker = L.circleMarker(
          loc,
          {
            radius: 4,
            opacity: 1.0,
            fillOpacity: 0.6,
            fillColor: (v.stale ? '#f00' : '#05A2F1'),
            color: (v.stale ? '#f00' : '#05A2F1')
          }
        );

      let popup = L.popup()
       .setLatLng(loc)
       .setContent('<p>' + v.name + '</p>');

      marker.addTo(this.map);
      marker.bringToFront();
      marker.bindPopup(popup);

      return marker;
    })

    this.markers[route] = markers;
  }
}

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

ready(() => {
  map = L.map('map', {zoomControl: false});

  new L.Control.Zoom({ position: 'topright' }).addTo(map);

  map.setView([29.951066, -90.071532], 13);

  L.tileLayer('http://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.{ext}', {
      attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      subdomains: 'abcd',
      minZoom: 12,
      maxZoom: 19,
      ext: 'png'
  }).addTo(map);

  window.application = new Application(map, window.params);

  ReactDOM.render(
    <Menu routes={window.routes} currentRoutes={window.application.getCurrentRoutes()} />,
    document.getElementById("menu")
  );
});

class Menu extends React.Component {

  constructor(props) {
    super(props);
    this.state = { currentRoutes: props.currentRoutes };
  }

  isRouteChosen(route) {
    return this.state.currentRoutes.includes(route)
  }

  toggleChosen(route) {
    let routes = this.state.currentRoutes.slice(0); // must clone
    let index = routes.indexOf(route);

    if (index > -1) {
      routes.splice(index, 1)
    } else {
      routes.push(route)
    }

    this.setState({currentRoutes: routes})

    window.application.setCurrentRoutes(routes);
    window.application.channel.push("vehicles:subscribe", {routes: routes})
  }

  render() {
    let routeLinks = this.props.routes.map((r) => {
      let id = r.route_short_name

      return (
          <li className="pure-menu-item">
            <a href="#" className={this.isRouteChosen(id) ? "pure-menu-link chosen" : "pure-menu-link"} onClick={this.toggleChosen.bind(this, id)}>
              {r.route_short_name} - {r.route_long_name}
            </a>
          </li>
      );
    })

    return (
        <div className="pure-menu">
          <a className="pure-menu-heading" href="#">NORTA Routes</a>
          <ul className="pure-menu-list">{routeLinks}</ul>
        </div>
    );
  }
}

