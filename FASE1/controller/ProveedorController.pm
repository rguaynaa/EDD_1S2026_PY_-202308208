package ProveedorController;
use strict;
use warnings;

use Proveedor;
use ListaProveedores;

my $listaProveedores = ListaProveedores->new();
my $idProveedor = 1;

sub crear_proveedor {
    print "Nombre proveedor: ";
    chomp(my $nombre = <STDIN>);
    print "Direccion: ";
    chomp(my $dir = <STDIN>);
    print "Telefono: ";
    chomp(my $tel = <STDIN>);

    my $p = Proveedor->new(
        id        => $idProveedor++,
        nombre    => $nombre,
        direccion => $dir,
        telefono  => $tel
    );

    $listaProveedores->agregar($p);
    print "Proveedor registrado.\n";
}

sub agregar_medicamento_proveedor {
    my $nodo = $listaProveedores->obtener_primero();
    return unless $nodo;

    print "Codigo medicamento a asociar: ";
    chomp(my $cod = <STDIN>);

    $nodo->get_dato()->agregar_medicamento($cod);
    print "Medicamento asociado al proveedor.\n";
}

1;