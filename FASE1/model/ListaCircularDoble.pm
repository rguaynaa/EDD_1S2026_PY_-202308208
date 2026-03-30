package ListaCircularDoble;
use strict;
use warnings;
use Nodo;

# Lista circular doblemente enlazada para solicitudes de reabastecimiento
#
# El ultimo nodo apunta de vuelta al primero (circular)
# Cada nodo tiene anterior y siguiente
#
#  ┌─────────────────────────────────────┐
#  ↓                                     │
# [S1] <-> [S2] <-> [S3] <-> [S4] ──────┘

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef,
        tamanio => 0,
    };
    bless $self, $class;
    return $self;
}

sub get_tamanio { $_[0]->{tamanio} }
sub esta_vacia  { !defined $_[0]->{primero} }

# ---------------------------------------------------------------
# AGREGAR al final de la lista circular
# ---------------------------------------------------------------
sub agregar {
    my ($self, $solicitud) = @_;
    my $nuevo = Nodo->new($solicitud);

    if ($self->esta_vacia()) {
        # El unico nodo apunta a si mismo
        $nuevo->set_siguiente($nuevo);
        $nuevo->set_anterior($nuevo);
        $self->{primero} = $nuevo;
    } else {
        # El ultimo es el anterior al primero
        my $ultimo = $self->{primero}->get_anterior();

        $ultimo->set_siguiente($nuevo);
        $nuevo->set_anterior($ultimo);
        $nuevo->set_siguiente($self->{primero});
        $self->{primero}->set_anterior($nuevo);
    }

    $self->{tamanio}++;
}

# ---------------------------------------------------------------
# VER la primera solicitud (sin eliminarla)
# ---------------------------------------------------------------
sub ver_primera {
    my ($self) = @_;
    return undef if $self->esta_vacia();
    return $self->{primero}->get_dato();
}

# ---------------------------------------------------------------
# ELIMINAR la primera solicitud (luego de aprobar o rechazar)
# ---------------------------------------------------------------
sub eliminar_primera {
    my ($self) = @_;
    return undef if $self->esta_vacia();

    my $dato = $self->{primero}->get_dato();

    if ($self->{tamanio} == 1) {
        $self->{primero} = undef;
    } else {
        my $ultimo  = $self->{primero}->get_anterior();
        my $segundo = $self->{primero}->get_siguiente();

        $segundo->set_anterior($ultimo);
        $ultimo->set_siguiente($segundo);
        $self->{primero} = $segundo;
    }

    $self->{tamanio}--;
    return $dato;
}

# ---------------------------------------------------------------
# LISTAR todas las solicitudes pendientes
# ---------------------------------------------------------------
sub listar {
    my ($self) = @_;

    if ($self->esta_vacia()) {
        print "No hay solicitudes pendientes.\n";
        return;
    }

    print "Total de solicitudes pendientes: " . $self->{tamanio} . "\n";
    print "-" x 60 . "\n";

    my $actual = $self->{primero};
    my $i      = 1;

    do {
        print "$i. " . $actual->get_dato()->to_string() . "\n";
        $actual = $actual->get_siguiente();
        $i++;
    } while ($actual != $self->{primero});
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reporte_solicitudes.dot";

    open my $fh, ">", $archivo or do {
        print "No se pudo crear el archivo DOT.\n";
        return;
    };

    print $fh "digraph ListaCircularDoble {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [shape=circle fontname=Arial style=filled fillcolor=lightyellow];\n\n";

    if ($self->esta_vacia()) {
        print $fh "  vacio [label=\"Sin solicitudes\" shape=plaintext];\n";
        print $fh "}\n";
        close $fh;
        return;
    }

    my $actual = $self->{primero};
    my @nodos;

    do {
        my $s   = $actual->get_dato();
        my $num = $s->get_numero();
        my $dep = $s->get_departamento();
        my $med = $s->get_codigo_med();
        my $pri = $s->get_prioridad();

        # Color segun prioridad
        my $color = "lightyellow";
        $color = "salmon"      if $pri eq "urgente";
        $color = "lightsalmon" if $pri eq "alta";
        $color = "lightblue"   if $pri eq "baja";

        print $fh "  S$num [label=\"#$num\\n$dep\\n$med\\n[$pri]\" style=filled fillcolor=$color];\n";
        push @nodos, "S$num";

        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});

    # Flechas circulares (adelante y atras)
    print $fh "\n  // flechas\n";
    my $n = scalar @nodos;
    for my $i (0 .. $n - 1) {
        my $sig = ($i + 1) % $n;
        print $fh "  $nodos[$i] -> $nodos[$sig];\n";
        print $fh "  $nodos[$sig] -> $nodos[$i] [style=dashed color=gray];\n";
    }

    # Indicar el total
    print $fh "\n  label=\"Solicitudes pendientes: $n\";\n";
    print $fh "}\n";
    close $fh;

    my $png = $archivo;
    $png =~ s/\.dot$/.png/;
    system("dot -Tpng $archivo -o $png");
    print "Reporte generado: $png\n";
}

1;
