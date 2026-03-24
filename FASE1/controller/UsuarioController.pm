package UsuarioController;
use strict;
use warnings;

use Solicitud;
use Inventario;
use ListaSolicitudes;

my $idSolicitud = 1;
my $inventario = Inventario->new();
my $listaSolicitudes = ListaSolicitudes->new();

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

    if ($m->bajoStock()) {
        print "⏳ En proceso de reabastecimiento\n";
    }
}

sub crear_solicitud {
    print "departamento: ";
    chomp(my $dep = <STDIN>);
    print "codigo medicamento: ";
    chomp(my $cod = <STDIN>);
    print "cantidad: ";
    chomp(my $cant = <STDIN>);
    print "prioridad (urgente/alta/media/baja): ";
    chomp(my $pri = <STDIN>);

    my $solicitud = Solicitud->new(
        id => $idSolicitud++,
        departamento => $dep,
        codigoMed => $cod,
        cantidad => $cant,
        prioridad => $pri,
        fecha => localtime(),
    );

    $listaSolicitudes->agregar($solicitud);
    print "Solicitud creada con ID: ", $solicitud->get_id(), " correctamente\n";

}
1;
