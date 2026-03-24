package ReporteProveedores;
use strict;
use warnings;

sub generar {
    my ($lista) = @_;
    my $nodo = $lista->obtener_primero();
    return unless $nodo;

    open my $fh, ">", "proveedores.dot" or return;

    print $fh "digraph Proveedores {\n";
    print $fh "node [shape=folder];\n";

    my $inicio = $nodo;
    do {
        my $p = $nodo->get_dato();
        print $fh "\"P$p->{id}\" [label=\"$p->{nombre}\"];\n";

        foreach my $med (@{$p->{medicamentos}}) {
            print $fh "\"P$p->{id}\" -> \"$med\";\n";
        }

        $nodo = $nodo->get_siguiente();
    } while ($nodo != $inicio);

    print $fh "}\n";
    close $fh;
}

1;