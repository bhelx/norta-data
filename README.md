# NORTA Data

The intent of this project is to make it easy to use up to date information from the New Orleans RTA.
It exposes json endpoints for the GTFS data and a websocket endpoint for the realtime information.

I hope to create client libraries for Android and ios.

## Documentation

There is currently no documentation for this API but I am working on documentation for the underlying [GTFS and Realtime data](data/norta_realtime_api.md).

## Hosted

There is currently a realtime map hosted on heroku. It might take some reloads to wake up the free Heroku instance. Also it may be down sometime
because the free time quota get's exhausted. I plan on hosting this on digital ocean in the future.

https://norta.herokuapp.com/?routes[]=12&routes[]=11&stale=true

## Deploying

I'm hoping to support a hosted server but still checking on the legality of it. You can deploy your own server if you
have an API key from NORTA.

This is a Phoenix application so you can mostly follow [their guide](http://www.phoenixframework.org/docs/heroku) except for a few tweaks. I'm going to lay out the steps here:

* Make sure you have a heroku account and a working install of heroku toolbelt
* Create your heroku app (you can put a name after create for a custom name `heroku create myappnam --buildpack.....`)

```
$ heroku create --buildpack "https://github.com/HashNuke/heroku-buildpack-elixir.git"
Creating mysterious-meadow-6277... done, stack is cedar-14
Buildpack set. Next release on mysterious-meadow-6277 will use https://github.com/HashNuke/heroku-buildpack-elixir.git.
https://mysterious-meadow-6277.herokuapp.com/ | https://git.heroku.com/mysterious-meadow-6277.git
Git remote heroku added
```

* Add the phoeinix static buildpack:

```
$ heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
Buildpack added. Next release on mysterious-meadow-6277 will use:
  1. https://github.com/HashNuke/heroku-buildpack-elixir.git
  2. https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
Run `git push heroku master` to create a new release using these buildpacks.
```

* Add the postgres hobby addon

```
 heroku addons:create heroku-postgresql:hobby-dev
```

* Generate a secret

```
$ mix phoenix.gen.secret
xvafzY4y01jYuzLm3ecJqo008dVnU3CN4f+MamNd1Zue4pXvfvUjbiXT8akaIF53
```

* set `SECRET_KEY_BASE` config variable

```
heroku config:set SECRET_KEY_BASE="xvafzY4y01jYuzLm3ecJqo008dVnU3CN4f+MamNd1Zue4pXvfvUjbiXT8akaIF53"
```

* Set your hostname to the heroku hostname you created in step 1

```
heroku config:set HOSTNAME="mysterious-meadow-6277"
```

* Set your norta API key

```
heroku config:set NORTA_API_KEY="myapikey123"
```

* Run the database migrations

```
heroku run mix ecto.migrate
```

## Configure Android App

When you open the app on your phone you are asked to enter a server url. Enter:

```
https://mysterious-meadow-6277.herokuapp.com/update
```

where `mysterious-meadow-6277` would be your hostname
