package AndminController;
use strict;
use warnings;

sub menu_admin{
    print "\n=== Menu Administrador ===\n";
    print "1. Registrar Medicamentos\n";
    print "2. Ver Inventrario\n";
    print "0. Volver al menu principal\n";
    print "Seleccione una opcion: ";


    chomp(my $opcion = <STDIN>);
    if ($opcion == 1) {
        print "Registrar Medicamentos\n";
        # Aqui se llamaria a la funcion para registrar medicamentos
    }elsif ($opcion == 2) {
        print "Ver Inventario\n";
        # Aqui se llamaria a la funcion para ver el inventario
    }elsif ($opcion == 0) {
        print "Volviendo al menu principal...\n";
    }else {
        print "Opcion invalida\n";
    }
    
}

