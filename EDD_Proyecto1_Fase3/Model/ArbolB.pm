package NodoB;
use strict;
use warnings;

# Nodo del Arbol B Orden 4
# Max claves por nodo: 3 (orden - 1)
# Max hijos por nodo: 4 (orden)

sub new {
    my ($class) = @_;
    return bless {
        claves  => [],    # array de strings (codigos)
        datos   => [],    # array de objetos Suministro
        hijos   => [],    # array de NodoB
        es_hoja => 1,
    }, $class;
}

sub n_claves { scalar @{ $_[0]->{claves} } }
sub es_hoja  { $_[0]->{es_hoja} }
sub esta_lleno { scalar(@{ $_[0]->{claves} }) >= 3 }

# ============================================================
package ArbolB;
use strict;
use warnings;

# B-tree orden 4 (grado minimo t=2)
# - Cada nodo: min 1 clave, max 3 claves
# - Cada nodo interno: min 2 hijos, max 4 hijos
# - Todas las hojas al mismo nivel

use constant T => 2;  # grado minimo (orden = 2*T = 4)

sub new {
    my ($class) = @_;
    return bless { raiz => undef, tamanio => 0 }, $class;
}

sub esta_vacio  { !defined $_[0]->{raiz} }
sub get_tamanio { $_[0]->{tamanio} }

# ---------------------------------------------------------------
# INSERTAR
# ---------------------------------------------------------------
sub insertar {
    my ($self, $suministro) = @_;
    my $clave = $suministro->get_codigo();

    if ($self->esta_vacio()) {
        my $raiz = NodoB->new();
        push @{ $raiz->{claves} }, $clave;
        push @{ $raiz->{datos}  }, $suministro;
        $self->{raiz} = $raiz;
        $self->{tamanio}++;
        return;
    }

    # Si ya existe, no insertar
    if (defined $self->buscar($clave)) {
        print "Suministro ya existe: $clave\n";
        return;
    }

    # Si la raiz esta llena, dividirla primero
    if ($self->{raiz}->esta_lleno()) {
        my $nueva_raiz = NodoB->new();
        $nueva_raiz->{es_hoja} = 0;
        push @{ $nueva_raiz->{hijos} }, $self->{raiz};
        _dividir_hijo($nueva_raiz, 0);
        $self->{raiz} = $nueva_raiz;
    }

    _insertar_no_lleno($self->{raiz}, $suministro);
    $self->{tamanio}++;
}

# Divide el hijo i del nodo padre (hijo debe estar lleno)
sub _dividir_hijo {
    my ($padre, $i) = @_;
    my $hijo_lleno = $padre->{hijos}[$i];
    my $nuevo      = NodoB->new();
    $nuevo->{es_hoja} = $hijo_lleno->{es_hoja};

    # Copiar la mitad derecha al nuevo nodo (indices T..2T-2 = 2..2)
    for my $j (0 .. T - 2) {
        push @{ $nuevo->{claves} }, $hijo_lleno->{claves}[T + $j];
        push @{ $nuevo->{datos}  }, $hijo_lleno->{datos} [T + $j];
    }
    # Copiar hijos si no es hoja
    unless ($hijo_lleno->{es_hoja}) {
        for my $j (0 .. T - 1) {
            push @{ $nuevo->{hijos} }, $hijo_lleno->{hijos}[T + $j];
        }
        splice @{ $hijo_lleno->{hijos} }, T;
    }

    # La clave del medio sube al padre
    my $clave_media = $hijo_lleno->{claves}[T - 1];
    my $dato_medio  = $hijo_lleno->{datos} [T - 1];

    # Truncar hijo_lleno (queda con T-1 claves)
    splice @{ $hijo_lleno->{claves} }, T - 1;
    splice @{ $hijo_lleno->{datos}  }, T - 1;

    # Insertar clave media en el padre en la posicion i
    splice @{ $padre->{claves} }, $i, 0, $clave_media;
    splice @{ $padre->{datos}  }, $i, 0, $dato_medio;
    # Insertar nuevo nodo en hijos[i+1]
    splice @{ $padre->{hijos} }, $i + 1, 0, $nuevo;
}

# Insertar en un nodo que NO esta lleno
sub _insertar_no_lleno {
    my ($nodo, $suministro) = @_;
    my $clave = $suministro->get_codigo();
    my $i = $nodo->n_claves() - 1;

    if ($nodo->{es_hoja}) {
        # Encontrar posicion e insertar
        my $pos = 0;
        $pos++ while $pos < $nodo->n_claves() && $clave gt $nodo->{claves}[$pos];
        splice @{ $nodo->{claves} }, $pos, 0, $clave;
        splice @{ $nodo->{datos}  }, $pos, 0, $suministro;
    } else {
        # Encontrar hijo correcto
        my $pos = 0;
        $pos++ while $pos < $nodo->n_claves() && $clave gt $nodo->{claves}[$pos];
        # Si el hijo esta lleno, dividirlo
        if ($nodo->{hijos}[$pos]->esta_lleno()) {
            _dividir_hijo($nodo, $pos);
            # Despues de dividir, ver a cual hijo bajar
            $pos++ if $clave gt $nodo->{claves}[$pos];
        }
        _insertar_no_lleno($nodo->{hijos}[$pos], $suministro);
    }
}

# ---------------------------------------------------------------
# BUSCAR por codigo
# ---------------------------------------------------------------
sub buscar {
    my ($self, $codigo) = @_;
    return undef if $self->esta_vacio();
    return _buscar_rec($self->{raiz}, $codigo);
}

sub _buscar_rec {
    my ($nodo, $codigo) = @_;
    return undef unless defined $nodo;

    my $i = 0;
    $i++ while $i < $nodo->n_claves() && $codigo gt $nodo->{claves}[$i];

    if ($i < $nodo->n_claves() && $codigo eq $nodo->{claves}[$i]) {
        return $nodo->{datos}[$i];
    }
    return undef if $nodo->{es_hoja};
    return _buscar_rec($nodo->{hijos}[$i], $codigo);
}

# ---------------------------------------------------------------
# ELIMINAR por codigo
# ---------------------------------------------------------------
sub eliminar {
    my ($self, $codigo) = @_;
    return 0 if $self->esta_vacio();

    my $ok = _eliminar_rec($self->{raiz}, $codigo);

    # Si la raiz queda vacia y tiene un hijo, el hijo se vuelve la nueva raiz
    if ($self->{raiz}->n_claves() == 0) {
        if ($self->{raiz}->{es_hoja}) {
            $self->{raiz} = undef;
        } else {
            $self->{raiz} = $self->{raiz}->{hijos}[0];
        }
    }

    $self->{tamanio}-- if $ok;
    return $ok;
}

sub _eliminar_rec {
    my ($nodo, $codigo) = @_;
    my $t = T;

    # Encontrar posicion de la clave
    my $i = 0;
    $i++ while $i < $nodo->n_claves() && $codigo gt $nodo->{claves}[$i];

    if ($i < $nodo->n_claves() && $codigo eq $nodo->{claves}[$i]) {
        # Clave encontrada en este nodo
        if ($nodo->{es_hoja}) {
            # Caso 1: hoja → eliminar directamente
            splice @{ $nodo->{claves} }, $i, 1;
            splice @{ $nodo->{datos}  }, $i, 1;
            return 1;
        } else {
            # Caso 2: nodo interno
            if ($nodo->{hijos}[$i]->n_claves() >= $t) {
                # 2a: predecesor (maximo del hijo izquierdo)
                my ($pred_clave, $pred_dato) = _maximo($nodo->{hijos}[$i]);
                $nodo->{claves}[$i] = $pred_clave;
                $nodo->{datos} [$i] = $pred_dato;
                return _eliminar_rec($nodo->{hijos}[$i], $pred_clave);
            } elsif ($nodo->{hijos}[$i+1]->n_claves() >= $t) {
                # 2b: sucesor (minimo del hijo derecho)
                my ($suc_clave, $suc_dato) = _minimo_b($nodo->{hijos}[$i+1]);
                $nodo->{claves}[$i] = $suc_clave;
                $nodo->{datos} [$i] = $suc_dato;
                return _eliminar_rec($nodo->{hijos}[$i+1], $suc_clave);
            } else {
                # 2c: merge hijo i, clave i, hijo i+1
                _merge($nodo, $i);
                return _eliminar_rec($nodo->{hijos}[$i], $codigo);
            }
        }
    } else {
        # Clave no esta en este nodo
        return 0 if $nodo->{es_hoja};

        my $es_ultimo = ($i == $nodo->n_claves());

        # Si el hijo tiene menos de t claves, arreglarlo
        if ($nodo->{hijos}[$i]->n_claves() < $t) {
            _arreglar_hijo($nodo, $i);
            # Despues de arreglar, puede que i haya cambiado
            if ($es_ultimo && $i > $nodo->n_claves()) {
                $i--;
            }
        }
        return _eliminar_rec($nodo->{hijos}[$i], $codigo);
    }
}

# Arreglar hijo[i] que tiene menos de t claves
sub _arreglar_hijo {
    my ($padre, $i) = @_;
    my $t = T;

    if ($i > 0 && $padre->{hijos}[$i-1]->n_claves() >= $t) {
        # Tomar prestado del hermano izquierdo
        _prestar_izquierdo($padre, $i);
    } elsif ($i < $padre->n_claves() && $padre->{hijos}[$i+1]->n_claves() >= $t) {
        # Tomar prestado del hermano derecho
        _prestar_derecho($padre, $i);
    } elsif ($i < $padre->n_claves()) {
        # Merge con hermano derecho
        _merge($padre, $i);
    } else {
        # Merge con hermano izquierdo
        _merge($padre, $i - 1);
    }
}

sub _prestar_izquierdo {
    my ($padre, $i) = @_;
    my $hijo = $padre->{hijos}[$i];
    my $hermano = $padre->{hijos}[$i - 1];

    # Mover clave del padre al inicio del hijo
    unshift @{ $hijo->{claves} }, $padre->{claves}[$i-1];
    unshift @{ $hijo->{datos}  }, $padre->{datos} [$i-1];

    # Mover ultimo hijo del hermano si no es hoja
    if (!$hijo->{es_hoja}) {
        unshift @{ $hijo->{hijos} }, pop @{ $hermano->{hijos} };
    }

    # Mover ultima clave del hermano al padre
    $padre->{claves}[$i-1] = pop @{ $hermano->{claves} };
    $padre->{datos} [$i-1] = pop @{ $hermano->{datos}  };
}

sub _prestar_derecho {
    my ($padre, $i) = @_;
    my $hijo = $padre->{hijos}[$i];
    my $hermano = $padre->{hijos}[$i + 1];

    # Mover clave del padre al final del hijo
    push @{ $hijo->{claves} }, $padre->{claves}[$i];
    push @{ $hijo->{datos}  }, $padre->{datos} [$i];

    # Mover primer hijo del hermano si no es hoja
    if (!$hijo->{es_hoja}) {
        push @{ $hijo->{hijos} }, shift @{ $hermano->{hijos} };
    }

    # Mover primera clave del hermano al padre
    $padre->{claves}[$i] = shift @{ $hermano->{claves} };
    $padre->{datos} [$i] = shift @{ $hermano->{datos}  };
}

# Merge: hijo[i], clave[i] del padre, hijo[i+1] → todo en hijo[i]
sub _merge {
    my ($padre, $i) = @_;
    my $hijo_izq = $padre->{hijos}[$i];
    my $hijo_der = $padre->{hijos}[$i + 1];

    # Bajar clave del padre al hijo izquierdo
    push @{ $hijo_izq->{claves} }, $padre->{claves}[$i];
    push @{ $hijo_izq->{datos}  }, $padre->{datos} [$i];

    # Copiar claves e hijos del hijo derecho
    push @{ $hijo_izq->{claves} }, @{ $hijo_der->{claves} };
    push @{ $hijo_izq->{datos}  }, @{ $hijo_der->{datos}  };
    unless ($hijo_izq->{es_hoja}) {
        push @{ $hijo_izq->{hijos} }, @{ $hijo_der->{hijos} };
    }

    # Eliminar clave[i] y hijo[i+1] del padre
    splice @{ $padre->{claves} }, $i, 1;
    splice @{ $padre->{datos}  }, $i, 1;
    splice @{ $padre->{hijos}  }, $i + 1, 1;
}

sub _minimo_b {
    my ($nodo) = @_;
    $nodo = $nodo->{hijos}[0] while !$nodo->{es_hoja};
    return ($nodo->{claves}[0], $nodo->{datos}[0]);
}

sub _maximo {
    my ($nodo) = @_;
    $nodo = $nodo->{hijos}[-1] while !$nodo->{es_hoja};
    return ($nodo->{claves}[-1], $nodo->{datos}[-1]);
}

# ---------------------------------------------------------------
# RECORRIDO INORDEN
# ---------------------------------------------------------------
sub inorden {
    my ($self) = @_;
    my @r;
    _inorden_b($self->{raiz}, \@r);
    return @r;
}

sub _inorden_b {
    my ($nodo, $r) = @_;
    return unless defined $nodo;
    for my $i (0 .. $nodo->n_claves() - 1) {
        _inorden_b($nodo->{hijos}[$i], $r) unless $nodo->{es_hoja};
        push @$r, $nodo->{datos}[$i];
    }
    _inorden_b($nodo->{hijos}[ $nodo->n_claves() ], $r) unless $nodo->{es_hoja};
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz (bloques horizontales segmentados)
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_arbol_b.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ArbolB {\n";
    print $fh "  node [shape=record fontname=Arial fontsize=9];\n";
    print $fh "  edge [arrowhead=vee];\n\n";

    if ($self->esta_vacio()) {
        print $fh "  vacio [label=\"Arbol B Vacio\" shape=plaintext];\n";
    } else {
        my $contador = [0];
        _dot_b_rec($self->{raiz}, $fh, $contador);
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte Arbol B generado: $png\n";
    return $png;
}

my %_nodo_ids;  # mapa nodo → id DOT

sub _dot_b_rec {
    my ($nodo, $fh, $contador) = @_;
    return unless defined $nodo;

    my $id = "nb" . (++$contador->[0]);
    $_nodo_ids{$nodo} = $id;

    # Color: amarillo si esta lleno (3 claves), verde si tiene espacio
    my $color = $nodo->esta_lleno() ? 'lightyellow' : 'lightgreen';

    # Construir label tipo record: {<f0> clave0 |<f1> clave1 |<f2> clave2}
    # Con puertos para las flechas a los hijos
    my @partes;
    for my $i (0 .. $nodo->n_claves() - 1) {
        push @partes, "<c$i>" if !$nodo->{es_hoja};
        push @partes, " " . $nodo->{claves}[$i] . " ";
    }
    push @partes, "<c" . $nodo->n_claves() . ">" if !$nodo->{es_hoja};

    my $label = join("|", @partes);
    my $cap = $nodo->n_claves() . "/3";

    print $fh "  $id [label=\"{$label | ($cap)}\" style=filled fillcolor=$color];\n";

    # Procesar hijos
    unless ($nodo->{es_hoja}) {
        for my $j (0 .. scalar(@{ $nodo->{hijos} }) - 1) {
            my $hijo = $nodo->{hijos}[$j];
            _dot_b_rec($hijo, $fh, $contador);
            my $hijo_id = $_nodo_ids{$hijo};
            print $fh "  $id:c$j -> $hijo_id;\n";
        }
    }
}

1;
