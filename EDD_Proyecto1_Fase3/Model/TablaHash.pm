package TablaHash;
use strict;
use warnings;

# ============================================================
# Tabla Hash - Directorio del Personal por Tipo
# Clave: tipo_usuario (TIPO-01 .. TIPO-04)
# Valor: lista de objetos Usuario
# Implementacion con encadenamiento (chaining) para colisiones
# Tamanio de tabla: 11 (primo, suficiente para los tipos)
# ============================================================

use constant TAMANIO => 11;

sub new {
    my ($class) = @_;
    my @tabla = map { [] } (0 .. TAMANIO - 1);
    return bless {
        tabla      => \@tabla,
        tamanio    => TAMANIO,
        total      => 0,
        colisiones => 0,
    }, $class;
}

# ---------------------------------------------------------------
# FUNCION HASH
# Suma de ord() de cada caracter mod TAMANIO
# ---------------------------------------------------------------
sub _hash {
    my ($self, $clave) = @_;
    my $suma = 0;
    $suma += ord($_) for split //, $clave;
    return $suma % $self->{tamanio};
}

# ---------------------------------------------------------------
# INSERTAR usuario
# ---------------------------------------------------------------
sub insertar {
    my ($self, $usuario) = @_;
    my $clave = $usuario->get_tipo_usuario();
    my $idx   = $self->_hash($clave);
    my $bucket = $self->{tabla}[$idx];

    # Verificar duplicado por numero_colegio
    for my $u (@$bucket) {
        return 0 if $u->get_numero_colegio() eq $usuario->get_numero_colegio();
    }

    $self->{colisiones}++ if @$bucket > 0;
    push @$bucket, $usuario;
    $self->{total}++;
    return 1;
}

# ---------------------------------------------------------------
# ELIMINAR usuario por numero_colegio
# ---------------------------------------------------------------
sub eliminar {
    my ($self, $col) = @_;
    for my $idx (0 .. $self->{tamanio} - 1) {
        my @nuevo = grep { $_->get_numero_colegio() ne $col } @{ $self->{tabla}[$idx] };
        if (scalar @nuevo < scalar @{ $self->{tabla}[$idx] }) {
            $self->{tabla}[$idx] = \@nuevo;
            $self->{total}--;
            return 1;
        }
    }
    return 0;
}

# ---------------------------------------------------------------
# BUSCAR todos los usuarios de un tipo
# ---------------------------------------------------------------
sub buscar_por_tipo {
    my ($self, $tipo) = @_;
    my $idx = $self->_hash($tipo);
    return grep { $_->get_tipo_usuario() eq $tipo } @{ $self->{tabla}[$idx] };
}

# ---------------------------------------------------------------
# BUSCAR usuario por numero_colegio
# ---------------------------------------------------------------
sub buscar {
    my ($self, $col) = @_;
    for my $bucket (@{ $self->{tabla} }) {
        for my $u (@$bucket) {
            return $u if $u->get_numero_colegio() eq $col;
        }
    }
    return undef;
}

# ---------------------------------------------------------------
# ESTADISTICAS para reporte
# ---------------------------------------------------------------
sub estadisticas {
    my ($self) = @_;
    my @stats;
    for my $idx (0 .. $self->{tamanio} - 1) {
        my $bucket = $self->{tabla}[$idx];
        my $n      = scalar @$bucket;
        my @tipos  = do {
            my %t;
            $t{$_->get_tipo_usuario()}++ for @$bucket;
            map { "$_($t{$_})" } sort keys %t;
        };
        push @stats, {
            slot      => $idx,
            ocupacion => $n,
            tipos     => join(', ', @tipos) || '',
            estado    => $n == 0 ? 'VACIO' : ($n == 1 ? 'OCUPADO' : 'COLISION'),
        };
    }
    return @stats;
}

sub get_total      { $_[0]->{total}      }
sub get_colisiones { $_[0]->{colisiones} }
sub get_tamanio    { $_[0]->{tamanio}    }

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# Muestra cada slot con su cadena de usuarios
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_hash.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph TablaHash {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [shape=record fontname=Arial fontsize=9];\n";
    print $fh "  edge [arrowhead=vee];\n\n";

    print $fh "  // Tabla\n";
    for my $idx (0 .. $self->{tamanio} - 1) {
        my $bucket = $self->{tabla}[$idx];
        my $n      = scalar @$bucket;
        my $color  = $n == 0 ? 'white' : ($n == 1 ? 'lightblue' : 'lightyellow');
        my $estado = $n == 0 ? 'VACÍO' : ($n == 1 ? "1 elem" : "$n (COLISION)");
        print $fh "  slot$idx [label=\"{[$idx] | $estado}\" style=filled fillcolor=$color];\n";

        # Cadena de usuarios (chaining)
        for my $i (0..$#$bucket) {
            my $u   = $bucket->[$i];
            my $uid = "u_${idx}_$i";
            my $col = $u->get_numero_colegio();
            my $nom = $u->get_nombre_completo(); $nom =~ s/[|<>"{}]//g;
            my $tip = $u->get_tipo_usuario();
            print $fh "  $uid [label=\"{$col | $nom | $tip}\" style=filled fillcolor=lightgreen];\n";
        }
    }

    print $fh "\n  // Flechas de slots a primeros elementos\n";
    for my $idx (0 .. $self->{tamanio} - 1) {
        my $bucket = $self->{tabla}[$idx];
        next unless @$bucket;
        print $fh "  slot$idx -> u_${idx}_0;\n";
        for my $i (0..$#$bucket-1) {
            print $fh "  u_${idx}_$i -> u_${idx}_" . ($i+1) . ";\n";
        }
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte Tabla Hash generado: $png\n";
    return $png;
}

1;
