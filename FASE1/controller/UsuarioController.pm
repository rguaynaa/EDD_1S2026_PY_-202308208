package UsuarioController;
use strict;
use warnings;
use Inventario;

my $inventario = Inventario->new();

sub menu_usuario{
    print "\n=== Menu Usuario ===\n";
    print "1. Buscar medicamento por codigo\n";
    print "2. Buscar medicamento por nombre\n";
    print "0. Volver al menu principal\n";
    print "Seleccione una opcion: ";


    chomp(my $opcion = <STDIN>);
    if ($opcion == 1) {
       print "Codigo: ";
        chomp(my $c = <STDIN>);
        my $m = $inventario->buscar($c);
        mostrar_medicamento_usuario($m);
    }elsif ($opcion == 2) {
        print "Nombre: ";
        chomp(my $n = <STDIN>);
        my $m = $inventario->buscar_por_nombre($n);
        mostrar_medicamento_usuario($m);

    }elsif ($opcion == 0) {
            print "Volviendo al menu principal...\n";
    }else {
            print "Opcion invalida\n";
    }

}

sub mostrar_medicamento_usuario {
    my ($m) = @_;

    if (!$m) {
        print "Medicamento no disponible.\n";
        return;
    }

    print "Nombre: ", $m->get_nombre(), "\n";
    print "Cantidad disponible: ", $m->get_cantidad(), "\n";

    if ($m->bajo_stock()) {
        print "⏳ En proceso de reabastecimiento\n";
    }
}

1;
