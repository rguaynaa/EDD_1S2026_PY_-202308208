package ReporteInventario;
use strict;
use warnings;

sub generar {
    my ($inventario) = @_;

    open my $fh, ">", "inventario.dot" or return;

    print $fh "digraph Inventario {\n";
    print $fh "node [shape=record];\n";

    $inventario->recorrer(sub {
        my ($m) = @_;
        print $fh "\"$m->{codigo}\" [label=\"{"
            . "Codigo: $m->{codigo}|"
            . "Nombre: $m->{nombre}|"
            . "Precio: Q$m->{precio}|"
            . "Cantidad: $m->{cantidad}"
            . "}\"];\n";
    });

    print $fh "}\n";
    close $fh;
}

1;