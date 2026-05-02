package ArbolMerkle;
use strict;
use warnings;

# ============================================================
# Arbol de Merkle - Trazabilidad de Solicitudes
# Cada hoja = una solicitud de reabastecimiento
# Cada nodo interno = hash combinado de sus hijos
# Garantiza inmutabilidad: cualquier cambio altera el hash raiz
# ============================================================

# ---------------------------------------------------------------
# Hash simple (sin modulos externos)
# djb2 adaptado para strings -> hex de 8 digitos
# ---------------------------------------------------------------
sub _hash_str {
    my ($str) = @_;
    my $h = 5381;
    for my $c (split //, $str) {
        $h = (($h << 5) + $h + ord($c)) & 0xFFFFFFFF;
    }
    return sprintf("%08x", $h);
}

# ---------------------------------------------------------------
# NODO del arbol
# ---------------------------------------------------------------
package NodoMerkle;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        hash      => $args{hash}      // '',
        dato      => $args{dato}      // undef,   # Solicitud (solo en hojas)
        izquierdo => $args{izquierdo} // undef,
        derecho   => $args{derecho}   // undef,
        es_hoja   => $args{es_hoja}   // 1,
    }, $class;
}

sub get_hash      { $_[0]->{hash}      }
sub get_dato      { $_[0]->{dato}      }
sub get_izquierdo { $_[0]->{izquierdo} }
sub get_derecho   { $_[0]->{derecho}   }
sub es_hoja       { $_[0]->{es_hoja}   }

# ---------------------------------------------------------------
# ARBOL DE MERKLE
# ---------------------------------------------------------------
package ArbolMerkle;
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        raiz      => undef,
        hojas     => [],      # lista ordenada de solicitudes
    }, $class;
}

sub esta_vacio  { !defined $_[0]->{raiz} }
sub get_raiz    { $_[0]->{raiz} }
sub get_hojas   { @{ $_[0]->{hojas} } }

# ---------------------------------------------------------------
# AGREGAR solicitud y reconstruir el arbol
# ---------------------------------------------------------------
sub agregar_solicitud {
    my ($self, $solicitud) = @_;
    push @{ $self->{hojas} }, $solicitud;
    $self->_reconstruir();
}

# ---------------------------------------------------------------
# RECONSTRUIR el arbol desde las hojas
# ---------------------------------------------------------------
sub _reconstruir {
    my ($self) = @_;
    return unless @{ $self->{hojas} };

    # Crear nodos hoja
    my @nivel = map {
        my $s    = $_;
        my $data = $s->serializar();
        NodoMerkle->new(
            hash    => ArbolMerkle::_hash_str($data),
            dato    => $s,
            es_hoja => 1,
        );
    } @{ $self->{hojas} };

    # Subir nivel por nivel hasta llegar a la raiz
    while (@nivel > 1) {
        my @nuevo_nivel;
        for (my $i = 0; $i < @nivel; $i += 2) {
            my $izq = $nivel[$i];
            my $der = $nivel[$i+1] // $nivel[$i];  # duplicar ultimo si impar

            my $hash_combinado = ArbolMerkle::_hash_str(
                $izq->get_hash() . $der->get_hash()
            );

            my $nodo = NodoMerkle->new(
                hash      => $hash_combinado,
                izquierdo => $izq,
                derecho   => ($i+1 < @nivel) ? $der : undef,
                es_hoja   => 0,
            );
            push @nuevo_nivel, $nodo;
        }
        @nivel = @nuevo_nivel;
    }

    $self->{raiz} = $nivel[0];
}

# ---------------------------------------------------------------
# VERIFICAR INTEGRIDAD
# Retorna 1 si el hash raiz es consistente con las hojas
# ---------------------------------------------------------------
sub verificar_integridad {
    my ($self) = @_;
    return 1 if $self->esta_vacio();

    # Recalcular hash raiz desde cero y comparar
    my $merkle_temp = ArbolMerkle->new();
    for my $s (@{ $self->{hojas} }) {
        push @{ $merkle_temp->{hojas} }, $s;
    }
    $merkle_temp->_reconstruir();

    return 0 unless defined $merkle_temp->{raiz};
    return $self->{raiz}->get_hash() eq $merkle_temp->{raiz}->get_hash();
}

sub get_hash_raiz {
    my ($self) = @_;
    return $self->esta_vacio() ? '(vacío)' : $self->{raiz}->get_hash();
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_merkle.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ArbolMerkle {\n";
    print $fh "  node [shape=record fontname=Arial fontsize=8];\n";
    print $fh "  edge [arrowhead=vee];\n\n";

    if ($self->esta_vacio()) {
        print $fh "  vacio [label=\"Arbol Merkle Vacio\" shape=plaintext];\n";
    } else {
        my $contador = [0];
        _dot_merkle_rec($self->{raiz}, $fh, $contador, undef);
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte Arbol Merkle generado: $png\n";
    return $png;
}

sub _dot_merkle_rec {
    my ($nodo, $fh, $cnt, $padre_id) = @_;
    return unless defined $nodo;

    my $id    = "m" . (++$cnt->[0]);
    my $hash  = substr($nodo->get_hash(), 0, 8);

    if ($nodo->es_hoja() && defined $nodo->get_dato()) {
        my $s     = $nodo->get_dato();
        my $label = $s->get_codigo() // '?';
        $label =~ s/[|<>"{}]//g;
        print $fh "  $id [label=\"{HOJA | $label | $hash}\" style=filled fillcolor=lightgreen];\n";
    } else {
        print $fh "  $id [label=\"{INTERNO | $hash}\" style=filled fillcolor=lightblue];\n";
    }

    print $fh "  $padre_id -> $id;\n" if defined $padre_id;

    _dot_merkle_rec($nodo->get_izquierdo(), $fh, $cnt, $id);
    _dot_merkle_rec($nodo->get_derecho(),   $fh, $cnt, $id);
}

1;
