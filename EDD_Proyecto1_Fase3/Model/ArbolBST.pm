package NodoBST;
use strict;
use warnings;

sub new {
    my ($class, $dato) = @_;
    return bless {
        dato      => $dato,
        izquierdo => undef,
        derecho   => undef,
    }, $class;
}
sub get_dato      { $_[0]->{dato}      }
sub get_izquierdo { $_[0]->{izquierdo} }
sub get_derecho   { $_[0]->{derecho}   }
sub set_izquierdo { $_[0]->{izquierdo} = $_[1] }
sub set_derecho   { $_[0]->{derecho}   = $_[1] }

# ============================================================
package ArbolBST;
use strict;
use warnings;

# BST ordenado por codigo de equipo (string comparison)

sub new {
    my ($class) = @_;
    return bless { raiz => undef, tamanio => 0 }, $class;
}

sub esta_vacio { !defined $_[0]->{raiz} }
sub get_tamanio { $_[0]->{tamanio} }

# ---------------------------------------------------------------
# INSERTAR
# ---------------------------------------------------------------
sub insertar {
    my ($self, $equipo) = @_;
    my ($nueva_raiz, $insertado) = _insertar_rec($self->{raiz}, $equipo);
    $self->{raiz} = $nueva_raiz;
    $self->{tamanio}++ if $insertado;
}

sub _insertar_rec {
    my ($nodo, $equipo) = @_;
    unless (defined $nodo) {
        return (NodoBST->new($equipo), 1);
    }
    my $cmp = $equipo->get_codigo() cmp $nodo->get_dato()->get_codigo();
    if ($cmp < 0) {
        my ($hijo, $ok) = _insertar_rec($nodo->get_izquierdo(), $equipo);
        $nodo->set_izquierdo($hijo);
        return ($nodo, $ok);
    } elsif ($cmp > 0) {
        my ($hijo, $ok) = _insertar_rec($nodo->get_derecho(), $equipo);
        $nodo->set_derecho($hijo);
        return ($nodo, $ok);
    } else {
        print "Equipo ya existe: " . $equipo->get_codigo() . "\n";
        return ($nodo, 0);
    }
}

# ---------------------------------------------------------------
# BUSCAR por codigo
# ---------------------------------------------------------------
sub buscar {
    my ($self, $codigo) = @_;
    return _buscar_rec($self->{raiz}, $codigo);
}

sub _buscar_rec {
    my ($nodo, $codigo) = @_;
    return undef unless defined $nodo;
    my $cmp = $codigo cmp $nodo->get_dato()->get_codigo();
    if    ($cmp == 0) { return $nodo->get_dato() }
    elsif ($cmp <  0) { return _buscar_rec($nodo->get_izquierdo(), $codigo) }
    else              { return _buscar_rec($nodo->get_derecho(),   $codigo) }
}

# ---------------------------------------------------------------
# ELIMINAR por codigo
# ---------------------------------------------------------------
sub eliminar {
    my ($self, $codigo) = @_;
    my ($nueva_raiz, $eliminado) = _eliminar_rec($self->{raiz}, $codigo);
    $self->{raiz} = $nueva_raiz;
    $self->{tamanio}-- if $eliminado;
    return $eliminado;
}

sub _eliminar_rec {
    my ($nodo, $codigo) = @_;
    return (undef, 0) unless defined $nodo;

    my $cmp = $codigo cmp $nodo->get_dato()->get_codigo();
    if ($cmp < 0) {
        my ($hijo, $ok) = _eliminar_rec($nodo->get_izquierdo(), $codigo);
        $nodo->set_izquierdo($hijo);
        return ($nodo, $ok);
    } elsif ($cmp > 0) {
        my ($hijo, $ok) = _eliminar_rec($nodo->get_derecho(), $codigo);
        $nodo->set_derecho($hijo);
        return ($nodo, $ok);
    } else {
        # Nodo encontrado
        # Caso 1: sin hijo izquierdo
        return ($nodo->get_derecho(), 1) unless defined $nodo->get_izquierdo();
        # Caso 2: sin hijo derecho
        return ($nodo->get_izquierdo(), 1) unless defined $nodo->get_derecho();
        # Caso 3: dos hijos → sucesor inorden (minimo del subarbol derecho)
        my $sucesor = _minimo($nodo->get_derecho());
        $nodo->{dato} = $sucesor->get_dato();
        my ($hijo, $_ok) = _eliminar_rec($nodo->get_derecho(), $sucesor->get_dato()->get_codigo());
        $nodo->set_derecho($hijo);
        return ($nodo, 1);
    }
}

sub _minimo {
    my ($nodo) = @_;
    $nodo = $nodo->get_izquierdo() while defined $nodo->get_izquierdo();
    return $nodo;
}

# ---------------------------------------------------------------
# RECORRIDOS  (retornan array de objetos Equipo)
# ---------------------------------------------------------------
sub inorden {
    my ($self) = @_;
    my @r;
    _inorden_rec($self->{raiz}, \@r);
    return @r;
}
sub _inorden_rec {
    my ($n, $r) = @_;
    return unless defined $n;
    _inorden_rec($n->get_izquierdo(), $r);
    push @$r, $n->get_dato();
    _inorden_rec($n->get_derecho(), $r);
}

sub preorden {
    my ($self) = @_;
    my @r;
    _preorden_rec($self->{raiz}, \@r);
    return @r;
}
sub _preorden_rec {
    my ($n, $r) = @_;
    return unless defined $n;
    push @$r, $n->get_dato();
    _preorden_rec($n->get_izquierdo(), $r);
    _preorden_rec($n->get_derecho(), $r);
}

sub postorden {
    my ($self) = @_;
    my @r;
    _postorden_rec($self->{raiz}, \@r);
    return @r;
}
sub _postorden_rec {
    my ($n, $r) = @_;
    return unless defined $n;
    _postorden_rec($n->get_izquierdo(), $r);
    _postorden_rec($n->get_derecho(), $r);
    push @$r, $n->get_dato();
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_bst.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ArbolBST {\n";
    print $fh "  node [shape=record fontname=Arial fontsize=10];\n";
    print $fh "  edge [arrowhead=vee];\n\n";

    if ($self->esta_vacio()) {
        print $fh "  vacio [label=\"BST Vacio\" shape=plaintext];\n";
    } else {
        _dot_rec($self->{raiz}, $fh, undef, '');
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
   system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte BST generado: $png\n";
    return $png;
}

sub _dot_rec {
    my ($nodo, $fh, $padre, $lado) = @_;
    return unless defined $nodo;

    my $e     = $nodo->get_dato();
    my $id    = $e->get_codigo();
    my $nom   = $e->get_nombre(); $nom =~ s/[|<>"{}]//g;
    my $cant  = $e->get_cantidad();
    my $color = $e->bajo_stock() ? 'salmon' : 'lightgreen';

    # Es hoja?
    my $es_hoja = !defined($nodo->get_izquierdo()) && !defined($nodo->get_derecho());
    my $borde   = $es_hoja ? 'style=filled,fillcolor=' . $color
                           : 'style=filled,fillcolor=' . $color;

    print $fh "  \"$id\" [label=\"{$id | $nom | Cant: $cant}\" $borde];\n";

    if (defined $padre) {
        print $fh "  \"$padre\" -> \"$id\" [label=\"$lado\"];\n";
    }

    _dot_rec($nodo->get_izquierdo(), $fh, $id, 'L');
    _dot_rec($nodo->get_derecho(),   $fh, $id, 'R');
}

1;
