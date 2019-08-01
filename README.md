# Vigisade

* [Setup](#setup)
* [About setup issues](#about-setup-issues)
* [Options](#options)


## Setup

* Clone the repository: `git clone git@gitlab.brocelia.net:sade/vigisade/vigisade.git`
* Initialize the main project: `make init`;
* Initialize the web project: `make init-web`;
* Initialize the Angular project: `make init-pwa`;

Then open your sub-project in PhpStorm.

You must run containers each time with `make up`.

## About setup issues

__docker-compose doesn't find the required version.__

Run `sudo pip3 install --upgrade docker-compose` to update your docker-compose.

__How to log in?__

* Load fixtures: `make db-fixtures` in the `vigisade-web` directory.
* Go to `/admin`.
* Log in with this account: `admin_0@gmail.com` / `12345678`.
* From the dashboard, you can enable and update any account.


## Use PhpMyAdmin

If you want to use PhpMyAdmin for database administration, you must include the compose file:

```
make pma-on
make up
```

## Options

### Host

You should use the following command if you want a DSN: `make init-host`.

Then you can access [vigisade.dev.brocelia.net](https://vigisade.dev.brocelia.net).

### Angular

You can work with `ng serve` using these commands:

```
make ngserve-on up
sleep 10 # time to build
open https://vigisade.dev.brocelia.net/
```
