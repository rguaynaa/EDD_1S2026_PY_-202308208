#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/model";
use lib "$FindBin::Bin/controller";

use AdminController;
use UsuarioController;

sub menu_principal {
    print "\n=== EDD MedTrack ===\n";
    print "1. Administrador\n";
    print "2. Usuario Departamental\n";
    print "0. Salir\n";
    print "Seleccione una opcion: ";
}

my $opcion;
do {
    menu_principal();
    chomp($opcion = <STDIN>);

    if ($opcion == 1) {
        AdminController::menu_admin();
    }
    elsif ($opcion == 2) {
        UsuarioController::menu_usuario();
    }
    elsif ($opcion == 0) {
        print "Saliendo del sistema...\n";
    }
    else {
        print "Opcion invalida\n";
    }
} while ($opcion != 0);

#prueba medicamento

use Medicamento;
 
my $m = Medicamento->new({
    codigo => 'MED001',
    nombre => 'Paracetamol',
    principioActivo => 'Paracetamol',
    laboratorio => 'Lab A',
    cantidad => 100,
    fechaVencimiento => '2025-12-31',
    precio => 10.5,
    nivelMinimo => 20,
});
print "Codigo: " . $m->get_codigo() . "\n";
print "bajo stock? " . ($m->bajoStock() ? "Si" : "No") . "\n";