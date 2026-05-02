package NodoAVL;
use strict;
use warnings;

sub new {
    my ($class, $dato) = @_;
    return bless {
        dato      => $dato,
        izquierdo => undef,
        derecho   => undef,
        altura    => 0,
    }, $class;
}
sub get_dato      { $_[0]->{dato}      }
sub get_izquierdo { $_[0]->{izquierdo} }
sub get_derecho   { $_[0]->{derecho}   }
sub get_altura    { $_[0]->{altura}    }
sub set_izquierdo { $_[0]->{izquierdo} = $_[1] }
sub set_derecho   { $_[0]->{derecho}   = $_[1] }
sub set_altura    { $_[0]->{altura}    = $_[1] }

# ============================================================
package ArbolAVL;
use strict;
use warnings;

# AVL ordenado por numero_colegio
# Garantiza O(log n) en busqueda, insercion y eliminacion

sub new {
    my ($class) = @_;
    return bless { raiz => undef, tamanio => 0 }, $class;
}

sub esta_vacio  { !defined $_[0]->{raiz} }
sub get_tamanio { $_[0]->{tamanio} }

# ---------------------------------------------------------------
# HELPERS de altura y balance
# ---------------------------------------------------------------
sub _altura {
    my ($n) = @_;
    return -1 unless defined $n;
    return $n->get_altura();
}

sub _actualizar_altura {
    my ($n) = @_;
    my $h = 1 + _max(_altura($n->get_izquierdo()), _altura($n->get_derecho()));
    $n->set_altura($h);
}

sub _balance {
    my ($n) = @_;
    return 0 unless defined $n;
    return _altura($n->get_izquierdo()) - _altura($n->get_derecho());
}

sub _max { $_[0] > $_[1] ? $_[0] : $_[1] }

# ---------------------------------------------------------------
# ROTACIONES
# ---------------------------------------------------------------
#   Rotacion Derecha (caso LL)
#       y              x
#      / \            / \
#     x   T3   →   T1   y
#    / \               / \
#   T1  T2           T2  T3
sub _rotar_derecha {
    my ($y) = @_;
    my $x  = $y->get_izquierdo();
    my $T2 = $x->get_derecho();

    $x->set_derecho($y);
    $y->set_izquierdo($T2);

    _actualizar_altura($y);
    _actualizar_altura($x);
    return $x;
}

#   Rotacion Izquierda (caso RR)
#     x                y
#    / \              / \
#   T1   y    →      x   T3
#       / \         / \
#      T2  T3      T1  T2
sub _rotar_izquierda {
    my ($x) = @_;
    my $y  = $x->get_derecho();
    my $T2 = $y->get_izquierdo();

    $y->set_izquierdo($x);
    $x->set_derecho($T2);

    _actualizar_altura($x);
    _actualizar_altura($y);
    return $y;
}

# Rebalancear si es necesario
sub _rebalancear {
    my ($nodo) = @_;
    _actualizar_altura($nodo);
    my $bf = _balance($nodo);

    # Caso LL: balance > 1 y subarbol izquierdo no es derecho-pesado
    if ($bf > 1 && _balance($nodo->get_izquierdo()) >= 0) {
        return _rotar_derecha($nodo);
    }
    # Caso LR: balance > 1 y subarbol izquierdo es derecho-pesado
    if ($bf > 1 && _balance($nodo->get_izquierdo()) < 0) {
        $nodo->set_izquierdo(_rotar_izquierda($nodo->get_izquierdo()));
        return _rotar_derecha($nodo);
    }
    # Caso RR: balance < -1 y subarbol derecho no es izquierdo-pesado
    if ($bf < -1 && _balance($nodo->get_derecho()) <= 0) {
        return _rotar_izquierda($nodo);
    }
    # Caso RL: balance < -1 y subarbol derecho es izquierdo-pesado
    if ($bf < -1 && _balance($nodo->get_derecho()) > 0) {
        $nodo->set_derecho(_rotar_derecha($nodo->get_derecho()));
        return _rotar_izquierda($nodo);
    }
    return $nodo;
}

# ---------------------------------------------------------------
# INSERTAR
# ---------------------------------------------------------------
sub insertar {
    my ($self, $usuario) = @_;
    my ($nueva_raiz, $ok) = _insertar_rec($self->{raiz}, $usuario);
    $self->{raiz} = $nueva_raiz;
    $self->{tamanio}++ if $ok;
    return $ok;
}

sub _insertar_rec {
    my ($nodo, $usuario) = @_;
    unless (defined $nodo) {
        return (NodoAVL->new($usuario), 1);
    }

    my $cmp = $usuario->get_numero_colegio() cmp $nodo->get_dato()->get_numero_colegio();
    if ($cmp < 0) {
        my ($hijo, $ok) = _insertar_rec($nodo->get_izquierdo(), $usuario);
        $nodo->set_izquierdo($hijo);
        return (_rebalancear($nodo), $ok);
    } elsif ($cmp > 0) {
        my ($hijo, $ok) = _insertar_rec($nodo->get_derecho(), $usuario);
        $nodo->set_derecho($hijo);
        return (_rebalancear($nodo), $ok);
    } else {
        print "Usuario ya existe: " . $usuario->get_numero_colegio() . "\n";
        return ($nodo, 0);
    }
}

# ---------------------------------------------------------------
# BUSCAR por numero_colegio
# ---------------------------------------------------------------
sub buscar {
    my ($self, $numero_colegio) = @_;
    return _buscar_rec($self->{raiz}, $numero_colegio);
}

sub _buscar_rec {
    my ($nodo, $col) = @_;
    return undef unless defined $nodo;
    my $cmp = $col cmp $nodo->get_dato()->get_numero_colegio();
    if    ($cmp == 0) { return $nodo->get_dato() }
    elsif ($cmp <  0) { return _buscar_rec($nodo->get_izquierdo(), $col) }
    else              { return _buscar_rec($nodo->get_derecho(),   $col) }
}

# ---------------------------------------------------------------
# ELIMINAR por numero_colegio
# ---------------------------------------------------------------
sub eliminar {
    my ($self, $numero_colegio) = @_;
    my ($nueva_raiz, $ok) = _eliminar_rec($self->{raiz}, $numero_colegio);
    $self->{raiz} = $nueva_raiz;
    $self->{tamanio}-- if $ok;
    return $ok;
}

sub _eliminar_rec {
    my ($nodo, $col) = @_;
    return (undef, 0) unless defined $nodo;

    my $cmp = $col cmp $nodo->get_dato()->get_numero_colegio();
    if ($cmp < 0) {
        my ($hijo, $ok) = _eliminar_rec($nodo->get_izquierdo(), $col);
        $nodo->set_izquierdo($hijo);
        return (_rebalancear($nodo), $ok);
    } elsif ($cmp > 0) {
        my ($hijo, $ok) = _eliminar_rec($nodo->get_derecho(), $col);
        $nodo->set_derecho($hijo);
        return (_rebalancear($nodo), $ok);
    } else {
        # Nodo encontrado
        unless (defined $nodo->get_izquierdo()) { return ($nodo->get_derecho(), 1) }
        unless (defined $nodo->get_derecho())   { return ($nodo->get_izquierdo(), 1) }
        # Dos hijos: sucesor inorden
        my $sucesor = _minimo_avl($nodo->get_derecho());
        $nodo->{dato} = $sucesor->get_dato();
        my ($hijo, $_ok) = _eliminar_rec($nodo->get_derecho(), $sucesor->get_dato()->get_numero_colegio());
        $nodo->set_derecho($hijo);
        return (_rebalancear($nodo), 1);
    }
}

sub _minimo_avl {
    my ($n) = @_;
    $n = $n->get_izquierdo() while defined $n->get_izquierdo();
    return $n;
}

# ---------------------------------------------------------------
# RECORRIDOS
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
# GENERAR DOT para Graphviz (nodos circulares segun enunciado)
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_avl.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ArbolAVL {\n";
    print $fh "  node [shape=ellipse fontname=Arial fontsize=9];\n";
    print $fh "  edge [arrowhead=vee];\n\n";

    if ($self->esta_vacio()) {
        print $fh "  vacio [label=\"AVL Vacio\" shape=plaintext];\n";
    } else {
        _dot_avl_rec($self->{raiz}, $fh, undef, '');
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte AVL generado: $png\n";
    return $png;
}

sub _dot_avl_rec {
    my ($nodo, $fh, $padre_id, $lado) = @_;
    return unless defined $nodo;

    my $u   = $nodo->get_dato();
    my $id  = $u->get_numero_colegio();
    my $nom = $u->get_nombre_completo(); $nom =~ s/[|<>"{}]//g;
    my $dep = $u->get_departamento();
    my $tip = $u->get_tipo_usuario();
    my $bf  = _balance($nodo);

    my $color = 'lightblue';
    $color = 'lightyellow' if abs($bf) == 1;

    print $fh "  \"$id\" [label=\"$id\\n$nom\\n$tip | $dep\" style=filled fillcolor=$color];\n";

    if (defined $padre_id) {
        print $fh "  \"$padre_id\" -> \"$id\" [label=\"$lado\"];\n";
    }

    _dot_avl_rec($nodo->get_izquierdo(), $fh, $id, 'L');
    _dot_avl_rec($nodo->get_derecho(),   $fh, $id, 'R');
}

1;
