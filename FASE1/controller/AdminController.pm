package AdminController;
use strict;
use warnings;
use Inventario;
use Medicamento;

my $inventario = Inventario->new();

sub menu_admin{
    print "\n=== Menu Administrador ===\n";
    print "1. Registrar Medicamentos\n";
    print "2. Ver Inventrario\n";
    print "0. Volver al menu principal\n";
    print "Seleccione una opcion: ";


    chomp(my $opcion = <STDIN>);
    if ($opcion == 1) {
        registrar_medicamento();
    }elsif ($opcion == 2) {
        print "Ver Inventario\n";
        $inventario->listar();
    }elsif ($opcion == 0) {
        print "Volviendo al menu principal...\n";
    }else {
        print "Opcion invalida\n";
    }
    
}

sub registrar_medicamento{
    print "Codigo del medicamento: ";
    chomp(my $codigo = <STDIN>);
    print "Nombre del medicamento: ";
    chomp(my $nombre = <STDIN>);

    print "Ingrese la cantidad del medicamento: ";
    chomp(my $cantidad = <STDIN>);


    my $m = Medicamento->new({
        codigo => $codigo,
        nombre => $nombre,
        cantidad => $cantidad,
        
    });

    $inventario->insertar($m);
    print "Medicamento registrado exitosamente\n";
    
}

1;
