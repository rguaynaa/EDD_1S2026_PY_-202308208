package UsuarioController;
use strict;
use warnings;

sub menu_usuario{
    print "\n=== Menu Usuario ===\n";
    print "1. Consultar Medicamentos\n";
    print "2. solicitar reabastecimiento\n";
    print "0. Volver al menu principal\n";
    print "Seleccione una opcion: ";


    chomp(my $opcion = <STDIN>);
    if ($opcion == 1) {
        print "Consultar Medicamentos\n";
        # Aqui se llamaria a la funcion para consultar medicamentos
    }elsif ($opcion == 2) {
        print "Solicitar Reabastecimiento\n";
        # Aqui se llamaria a la funcion para ver el inventario
    }elsif ($opcion == 0) {
        print "Volviendo al menu principal...\n";
    }else {
        print "Opcion invalida\n";
    }

}

1;
