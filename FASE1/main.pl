#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/model";
use lib "$FindBin::Bin/controller";

use AdminController;
use UsuarioController;

# Credenciales del administrador
my $ADMIN_USER = 'admin';
my $ADMIN_PASS = 'admin123';

# ---------------------------------------------------------------
# MENU PRINCIPAL
# ---------------------------------------------------------------
my $opcion = '';
do {
    print "\n" . "=" x 40 . "\n";
    print "        EDD MedTrack - Fase 1\n";
    print "=" x 40 . "\n";
    print "1. Iniciar sesion como Administrador\n";
    print "2. Iniciar sesion como Usuario Departamental\n";
    print "0. Salir\n";
    print "Opcion: ";
    chomp($opcion = <STDIN>);

    if ($opcion eq '1') {
        print "Usuario: ";    chomp(my $user = <STDIN>);
        print "Contrasena: "; chomp(my $pass = <STDIN>);

        if ($user eq $ADMIN_USER && $pass eq $ADMIN_PASS) {
            print "Bienvenido, Administrador.\n";
            AdminController::menu();
        } else {
            print "Credenciales incorrectas.\n";
        }

    } elsif ($opcion eq '2') {
        UsuarioController::menu();

    } elsif ($opcion eq '0') {
        print "Hasta luego.\n";

    } else {
        print "Opcion invalida.\n";
    }

} while ($opcion ne '0');