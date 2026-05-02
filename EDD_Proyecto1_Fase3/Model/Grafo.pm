package Grafo;
use strict;
use warnings;

# ============================================================
# Grafo No Dirigido - Lista de Adyacencia
# Modela la red de colaboracion interprofesional del hospital.
# Cada nodo = profesional (numero_colegio)
# Cada arista = colaboracion activa entre dos profesionales
# ============================================================

sub new {
    my ($class) = @_;
    return bless {
        adyacencia  => {},   # { col => [ col_vecino, ... ] }
        solicitudes => [],   # [ { solicitante, receptor, estado } ]
    }, $class;
}

# ---------------------------------------------------------------
# AGREGAR NODO (cuando se registra un usuario)
# ---------------------------------------------------------------
sub agregar_nodo {
    my ($self, $col) = @_;
    $self->{adyacencia}{$col} //= [];
}

# ---------------------------------------------------------------
# ELIMINAR NODO (cuando se elimina un usuario)
# ---------------------------------------------------------------
sub eliminar_nodo {
    my ($self, $col) = @_;
    delete $self->{adyacencia}{$col};
    # Eliminar aristas que apunten a este nodo
    for my $k (keys %{ $self->{adyacencia} }) {
        $self->{adyacencia}{$k} = [ grep { $_ ne $col } @{ $self->{adyacencia}{$k} } ];
    }
    # Limpiar solicitudes
    $self->{solicitudes} = [ grep {
        $_->{solicitante} ne $col && $_->{receptor} ne $col
    } @{ $self->{solicitudes} } ];
}

# ---------------------------------------------------------------
# AGREGAR ARISTA (colaboracion activa entre dos nodos)
# ---------------------------------------------------------------
sub agregar_arista {
    my ($self, $a, $b) = @_;
    return if $self->son_colaboradores($a, $b);

    $self->{adyacencia}{$a} //= [];
    $self->{adyacencia}{$b} //= [];

    push @{ $self->{adyacencia}{$a} }, $b;
    push @{ $self->{adyacencia}{$b} }, $a;
}

# ---------------------------------------------------------------
# ELIMINAR ARISTA
# ---------------------------------------------------------------
sub eliminar_arista {
    my ($self, $a, $b) = @_;
    $self->{adyacencia}{$a} = [ grep { $_ ne $b } @{ $self->{adyacencia}{$a} // [] } ];
    $self->{adyacencia}{$b} = [ grep { $_ ne $a } @{ $self->{adyacencia}{$b} // [] } ];
}

# ---------------------------------------------------------------
# CONSULTAR si dos nodos son colaboradores
# ---------------------------------------------------------------
sub son_colaboradores {
    my ($self, $a, $b) = @_;
    return 0 unless exists $self->{adyacencia}{$a};
    return scalar grep { $_ eq $b } @{ $self->{adyacencia}{$a} };
}

# ---------------------------------------------------------------
# OBTENER vecinos (colaboradores directos) de un nodo
# ---------------------------------------------------------------
sub vecinos {
    my ($self, $col) = @_;
    return @{ $self->{adyacencia}{$col} // [] };
}

# ---------------------------------------------------------------
# OBTENER todos los nodos
# ---------------------------------------------------------------
sub nodos {
    my ($self) = @_;
    return keys %{ $self->{adyacencia} };
}

# ---------------------------------------------------------------
# SOLICITUDES DE COLABORACION
# ---------------------------------------------------------------
sub agregar_solicitud {
    my ($self, $solicitante, $receptor) = @_;
    # Verificar que no exista ya
    for my $s (@{ $self->{solicitudes} }) {
        return if $s->{solicitante} eq $solicitante && $s->{receptor} eq $receptor;
        return if $s->{solicitante} eq $receptor    && $s->{receptor} eq $solicitante;
    }
    push @{ $self->{solicitudes} }, {
        solicitante => $solicitante,
        receptor    => $receptor,
        estado      => 'PENDIENTE',
    };
}

sub aceptar_solicitud {
    my ($self, $solicitante, $receptor) = @_;
    for my $s (@{ $self->{solicitudes} }) {
        if ($s->{solicitante} eq $solicitante && $s->{receptor} eq $receptor) {
            $s->{estado} = 'ACTIVA';
            $self->agregar_arista($solicitante, $receptor);
            return 1;
        }
    }
    return 0;
}

sub rechazar_solicitud {
    my ($self, $solicitante, $receptor) = @_;
    for my $s (@{ $self->{solicitudes} }) {
        if ($s->{solicitante} eq $solicitante && $s->{receptor} eq $receptor) {
            $s->{estado} = 'RECHAZADA';
            return 1;
        }
    }
    return 0;
}

# Solicitudes pendientes recibidas por un usuario
sub solicitudes_recibidas {
    my ($self, $receptor) = @_;
    return grep { $_->{receptor} eq $receptor && $_->{estado} eq 'PENDIENTE' }
           @{ $self->{solicitudes} };
}

# Solicitudes enviadas por un usuario
sub solicitudes_enviadas {
    my ($self, $solicitante) = @_;
    return grep { $_->{solicitante} eq $solicitante }
           @{ $self->{solicitudes} };
}

# ---------------------------------------------------------------
# BFS DE DOS SALTOS - sugerencias de colaboracion
# Retorna: [ { col => ..., comunes => N }, ... ] ordenado desc
# ---------------------------------------------------------------
sub sugerencias {
    my ($self, $col) = @_;
    my %directos = map { $_ => 1 } $self->vecinos($col);
    my %comunes;

    for my $vecino (keys %directos) {
        for my $segundo ($self->vecinos($vecino)) {
            next if $segundo eq $col;
            next if exists $directos{$segundo};
            $comunes{$segundo}++;
        }
    }

    my @sugs = map { { col => $_, comunes => $comunes{$_} } }
               sort { $comunes{$b} <=> $comunes{$a} }
               keys %comunes;
    return @sugs;
}

# ---------------------------------------------------------------
# LISTA DE ADYACENCIA (texto)
# ---------------------------------------------------------------
sub lista_adyacencia_texto {
    my ($self) = @_;
    my $txt = '';
    for my $col (sort keys %{ $self->{adyacencia} }) {
        my @v = @{ $self->{adyacencia}{$col} };
        $txt .= "$col -> [" . join(", ", sort @v) . "]\n";
    }
    return $txt || "(Grafo vacío)\n";
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# Nodos coloreados por departamento
# ---------------------------------------------------------------
my %DEP_COLOR = (
    'DEP-ADM' => 'gold',
    'DEP-MED' => 'lightblue',
    'DEP-CIR' => 'lightgreen',
    'DEP-LAB' => 'lightsalmon',
    'DEP-FAR' => 'plum',
    'SIN-DEP' => 'lightgray',
);

sub generar_dot {
    my ($self, $archivo, $avl) = @_;
    $archivo //= "reports/reporte_grafo.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "graph RedColaboracion {\n";
    print $fh "  layout=neato;\n";
    print $fh "  node [shape=ellipse fontname=Arial fontsize=9];\n";
    print $fh "  edge [style=solid];\n\n";

    # Nodos
    for my $col (sort keys %{ $self->{adyacencia} }) {
        my $dep   = 'SIN-DEP';
        my $nom   = $col;
        my $tipo  = '';

        if ($avl) {
            my $u = $avl->buscar($col);
            if ($u) {
                $dep  = $u->get_departamento() || 'SIN-DEP';
                $nom  = $u->get_nombre_completo(); $nom =~ s/[|<>"{}]//g;
                $tipo = $u->get_tipo_usuario();
            }
        }

        my $color = $DEP_COLOR{$dep} // 'lightgray';
        print $fh "  \"$col\" [label=\"$col\\n$nom\\n$dep | $tipo\" style=filled fillcolor=\"$color\"];\n";
    }

    print $fh "\n";

    # Aristas (solo una vez por par no dirigido)
    my %visto;
    for my $a (sort keys %{ $self->{adyacencia} }) {
        for my $b (@{ $self->{adyacencia}{$a} }) {
            my $par = join('|', sort($a, $b));
            next if $visto{$par}++;
            print $fh "  \"$a\" -- \"$b\";\n";
        }
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte Grafo generado: $png\n";
    return $png;
}

# DOT de lista de adyacencia (tabla visual)
sub generar_dot_adyacencia {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_adyacencia.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ListaAdyacencia {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [shape=record fontname=Arial fontsize=9];\n\n";

    for my $col (sort keys %{ $self->{adyacencia} }) {
        my @v = sort @{ $self->{adyacencia}{$col} };
        my $id_safe = _esc($col);

        # Nodo cabecera
        print $fh "  h_$id_safe [label=\"<h> $col\" style=filled fillcolor=lightblue];\n";

        # Nodos de vecinos en cadena
        for my $i (0..$#v) {
            my $vid = "v_${id_safe}_$i";
            print $fh "  $vid [label=\"$v[$i]\" style=filled fillcolor=lightyellow];\n";
        }

        # Flechas
        if (@v) {
            print $fh "  h_$id_safe -> v_${id_safe}_0;\n";
            for my $i (0..$#v-1) {
                print $fh "  v_${id_safe}_$i -> v_${id_safe}_" . ($i+1) . ";\n";
            }
        }
        print $fh "\n";
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte Lista Adyacencia generado: $png\n";
    return $png;
}

sub _esc { my $s = $_[0]; $s =~ s/[^a-zA-Z0-9]/_/g; return $s }

1;
