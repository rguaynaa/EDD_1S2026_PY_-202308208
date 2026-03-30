#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/model";
use lib "$FindBin::Bin/view";

use Gtk3 -init;
use VentanaLogin;

# Iniciar la aplicacion GTK
VentanaLogin->nueva();
Gtk3->main();
