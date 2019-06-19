# Vigisade

* [Setup](#setup)
* [About setup issues](#about-setup-issues)
* [Options](#options)


## Setup

* Clone the repository: `git clone git@gitlab.brocelia.net:sade/vigisade/vigisade.git`
* Initialize the main project: `make init`;
* Initializer the web project: `make init-web`;

Then open your sub-project in PhpStorm.


## About setup issues

__docker-compose doesn't find the required version.__

Run `sudo pip3 install --upgrade docker-compose` to update your docker-compose.


## Options

You should use the following command if you want a DSN: `make init-host`.

Then you can access [www-dev.vigisade.com](www-dev.vigisade.com).


## HTTPS

    . .env
    echo $IP vigisade.dev.brocelia.net | sudo tee -a /etc/hosts"
    open https://vigisade.dev.brocelia.net/


## dev PWA with ng serve

    make ngserve-on up
    sleep 10 # time to build
    open https://vigisade.dev.brocelia.net/
