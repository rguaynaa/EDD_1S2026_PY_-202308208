package ReporteSolicitudes;
use strict;
use warnings;

sub generar {
    my ($lista) = @_;
    my $nodo = $lista->obtener_primera();
    return unless $nodo;

    open my $fh, ">", "solicitudes.dot" or return;

    print $fh "digraph Solicitudes {\n";
    print $fh "rankdir=LR;\n";
    print $fh "node [shape=box];\n";

    my $inicio = $nodo;
    do {
        my $s = $nodo->get_dato();
        print $fh "\"$s->{id}\" [label=\""
            . "ID: $s->{id}\\n"
            . "Depto: $s->{departamento}\\n"
            . "Med: $s->{codigoMed}\\n"
            . "Cant: $s->{cantidad}\\n"
            . "Estado: $s->{estado}"
            . "\"];\n";

        my $sig = $nodo->get_siguiente()->get_dato();
        print $fh "\"$s->{id}\" -> \"$sig->{id}\";\n";

        $nodo = $nodo->get_siguiente();
    } while ($nodo != $inicio);

    print $fh "}\n";
    close $fh;
}

1;