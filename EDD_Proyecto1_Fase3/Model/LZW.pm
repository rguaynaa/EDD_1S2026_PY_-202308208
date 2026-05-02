package LZW;
use strict;
use warnings;

# ============================================================
# Algoritmo de Compresion/Descompresion LZW
# Implementacion pura en Perl (sin modulos externos)
# Usado para persistir historiales de chat en disco
# ============================================================

# ---------------------------------------------------------------
# COMPRIMIR: texto (string) -> lista de codigos enteros
# ---------------------------------------------------------------
sub comprimir {
    my ($class, $texto) = @_;
    return [] unless defined $texto && length($texto) > 0;

    # Inicializar diccionario con ASCII basico (0-255)
    my %dict;
    for my $i (0..255) {
        $dict{ chr($i) } = $i;
    }
    my $siguiente_codigo = 256;

    my @salida;
    my $w = '';

    for my $c (split //, $texto) {
        my $wc = $w . $c;
        if (exists $dict{$wc}) {
            $w = $wc;
        } else {
            push @salida, $dict{$w};
            $dict{$wc} = $siguiente_codigo++;
            $w = $c;
        }
    }
    push @salida, $dict{$w} if length($w) > 0;

    return \@salida;
}

# ---------------------------------------------------------------
# DESCOMPRIMIR: lista de codigos -> texto original
# ---------------------------------------------------------------
sub descomprimir {
    my ($class, $codigos) = @_;
    return '' unless defined $codigos && @$codigos;

    # Inicializar diccionario inverso con ASCII
    my %dict;
    for my $i (0..255) {
        $dict{$i} = chr($i);
    }
    my $siguiente_codigo = 256;

    my @resultado;
    my $w = chr($codigos->[0]);
    push @resultado, $w;

    for my $i (1..$#$codigos) {
        my $k = $codigos->[$i];
        my $entrada;

        if (exists $dict{$k}) {
            $entrada = $dict{$k};
        } elsif ($k == $siguiente_codigo) {
            $entrada = $w . substr($w, 0, 1);
        } else {
            warn "LZW: codigo inesperado $k\n";
            last;
        }

        push @resultado, $entrada;
        $dict{$siguiente_codigo++} = $w . substr($entrada, 0, 1);
        $w = $entrada;
    }

    return join('', @resultado);
}

# ---------------------------------------------------------------
# GUARDAR archivo comprimido
# Formato: codigos separados por coma en una sola linea
# ---------------------------------------------------------------
sub guardar_archivo {
    my ($class, $codigos, $ruta) = @_;

    # Crear directorio si no existe
    (my $dir = $ruta) =~ s|/[^/]+$||;
    mkdir $dir unless -d $dir;

    open my $fh, '>', $ruta or do {
        warn "LZW: No se pudo crear $ruta: $!\n";
        return 0;
    };
    print $fh join(',', @$codigos) . "\n";
    close $fh;
    return 1;
}

# ---------------------------------------------------------------
# CARGAR archivo comprimido
# ---------------------------------------------------------------
sub cargar_archivo {
    my ($class, $ruta) = @_;
    return undef unless -e $ruta;

    open my $fh, '<', $ruta or do {
        warn "LZW: No se pudo abrir $ruta: $!\n";
        return undef;
    };
    my $linea = <$fh>;
    close $fh;

    chomp $linea;
    return undef unless defined $linea && length($linea) > 0;

    my @codigos = map { int($_) } split /,/, $linea;
    return \@codigos;
}

# ---------------------------------------------------------------
# SERIALIZAR historial de chats a texto estructurado
# Formato:
#   CONV|col_a|col_b
#   MSG|timestamp|remitente|contenido
#   ...
#   END_CONV
# ---------------------------------------------------------------
sub serializar_chats {
    my ($class, $chats_ref) = @_;
    # $chats_ref = { "col_a|col_b" => [ {ts, remit, contenido}, ... ] }
    my $texto = '';

    for my $par (sort keys %$chats_ref) {
        my ($ca, $cb) = split /\|/, $par;
        $texto .= "CONV|$ca|$cb\n";
        for my $msg (@{ $chats_ref->{$par} }) {
            # Escapar | en contenido
            my $cont = $msg->{contenido};
            $cont =~ s/\|/\x01/g;
            $cont =~ s/\n/\x02/g;
            $texto .= "MSG|$msg->{timestamp}|$msg->{remitente}|$cont\n";
        }
        $texto .= "END_CONV\n";
    }

    return $texto;
}

# ---------------------------------------------------------------
# DESERIALIZAR texto a estructura de chats
# ---------------------------------------------------------------
sub deserializar_chats {
    my ($class, $texto) = @_;
    my %chats;
    my $par_actual = '';

    for my $linea (split /\n/, $texto) {
        if ($linea =~ /^CONV\|(.+)\|(.+)$/) {
            my ($ca, $cb) = ($1, $2);
            $par_actual = join('|', sort($ca, $cb));
            $chats{$par_actual} //= [];
        } elsif ($linea =~ /^MSG\|([^\|]+)\|([^\|]+)\|(.*)$/) {
            my ($ts, $remit, $cont) = ($1, $2, $3);
            $cont =~ s/\x01/|/g;
            $cont =~ s/\x02/\n/g;
            push @{ $chats{$par_actual} }, {
                timestamp  => $ts,
                remitente  => $remit,
                contenido  => $cont,
            };
        } elsif ($linea eq 'END_CONV') {
            $par_actual = '';
        }
    }

    return \%chats;
}

# ---------------------------------------------------------------
# COMPRIMIR Y GUARDAR chats de un usuario
# ---------------------------------------------------------------
sub guardar_chats_usuario {
    my ($class, $col, $chats_ref, $dir) = @_;
    $dir //= 'chats';
    mkdir $dir unless -d $dir;

    my $texto   = $class->serializar_chats($chats_ref);
    my $codigos = $class->comprimir($texto);
    my $ruta    = "$dir/$col.lzw";
    return $class->guardar_archivo($codigos, $ruta);
}

# ---------------------------------------------------------------
# CARGAR Y DESCOMPRIMIR chats de un usuario
# ---------------------------------------------------------------
sub cargar_chats_usuario {
    my ($class, $col, $dir) = @_;
    $dir //= 'chats';
    my $ruta = "$dir/$col.lzw";

    my $codigos = $class->cargar_archivo($ruta);
    return {} unless defined $codigos && @$codigos;

    my $texto = $class->descomprimir($codigos);
    return $class->deserializar_chats($texto);
}

# ---------------------------------------------------------------
# GENERAR DOT reporte de archivos .lzw
# ---------------------------------------------------------------
sub generar_dot_archivos {
    my ($class, $dir, $archivo) = @_;
    $dir     //= 'chats';
    $archivo //= 'reports/reporte_lzw.dot';

    my @archivos_lzw;
    if (-d $dir) {
        opendir my $dh, $dir or die "No se pudo abrir $dir: $!";
        @archivos_lzw = grep { /\.lzw$/ } readdir($dh);
        closedir $dh;
    }

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ArchivosLZW {\n";
    print $fh "  rankdir=TB;\n";
    print $fh "  node [shape=folder fontname=Arial fontsize=9];\n\n";

    # Nodo carpeta
    print $fh "  chats [label=\"📁 chats/\" shape=folder style=filled fillcolor=gold];\n\n";

    if (@archivos_lzw) {
        for my $arch (sort @archivos_lzw) {
            my $ruta   = "$dir/$arch";
            my $size   = -e $ruta ? (stat($ruta))[7] : 0;
            my $col    = $arch; $col =~ s/\.lzw$//;
            my $id     = $col; $id =~ s/[^a-zA-Z0-9]/_/g;
            my $size_kb = sprintf("%.1f KB", $size / 1024);

            print $fh "  lzw_$id [label=\"$arch\\nTamanio: $size_kb\" shape=note style=filled fillcolor=lightblue];\n";
            print $fh "  chats -> lzw_$id;\n";
        }
    } else {
        print $fh "  vacio [label=\"(Sin archivos .lzw)\" shape=plaintext];\n";
        print $fh "  chats -> vacio;\n";
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte LZW generado: $png\n";
    return $png;
}

1;
