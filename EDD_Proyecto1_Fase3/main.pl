#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Gtk3 -init;

use FindBin;
use lib "$FindBin::Bin/model";
use lib "$FindBin::Bin/view";


use Nodo;
use Medicamento;
use Equipo;
use Suministro;
use Usuario;
use Proveedor;
use ListaDoble;
use ListaCircularDoble;
use MatrizDispersa;
use ArbolBST;
use ArbolAVL;
use ArbolB;

# Modelos F3 nuevos
use Grafo;
use TablaHash;
use LZW;
use ArbolMerkle;
use Solicitud;
use ListaSolicitudes;
use EstadoF3;

# Vista
use VentanaLogin;

# Crear directorios necesarios
mkdir 'reports' unless -d 'reports';
mkdir 'chats'   unless -d 'chats';

# Iniciar la aplicacion
VentanaLogin->nueva();
Gtk3->main();
