package Estado;
use strict;
use warnings;

use ListaDoble;
use ListaCircularDoble;
use MatrizDispersa;
use ArbolBST;
use ArbolAVL;
use ArbolB;

# ---------------------------------------------------------------
# SINGLETON - una sola instancia compartida por toda la app
# ---------------------------------------------------------------
my $instancia;

sub get_instancia {
    my ($class) = @_;
    unless (defined $instancia) {
        $instancia = bless {
            # Estructuras FASE1 que continuan
            medicamentos => ListaDoble->new(),          # MED - lista doble

            # Estructuras FASE2 nuevas
            equipos      => ArbolBST->new(),            # EQU - BST
            suministros  => ArbolB->new(),              # SUM - Arbol B ord 4
            usuarios     => ArbolAVL->new(),            # personal medico - AVL

            # Lista circular doble de proveedores (actualizada FASE2)
            proveedores  => ListaCircularDoble->new(),

            # Matriz dispersa: proveedor (fila) x fabricante (columna)
            matriz       => MatrizDispersa->new(),

            # Usuario logueado actualmente
            usuario_actual => undef,  # objeto Usuario o undef
            es_admin       => 0,

            # Directorio base para reportes
            dir_reportes => 'reports',
        }, $class;
    }
    return $instancia;
}

# ---------------------------------------------------------------
# Accesores rapidos
# ---------------------------------------------------------------
sub medicamentos { $_[0]->{medicamentos} }
sub equipos      { $_[0]->{equipos}      }
sub suministros  { $_[0]->{suministros}  }
sub usuarios     { $_[0]->{usuarios}     }
sub proveedores  { $_[0]->{proveedores}  }
sub matriz       { $_[0]->{matriz}       }

sub get_usuario_actual { $_[0]->{usuario_actual} }
sub set_usuario_actual { $_[0]->{usuario_actual} = $_[1] }
sub get_es_admin       { $_[0]->{es_admin}       }
sub set_es_admin       { $_[0]->{es_admin}       = $_[1] }

sub dir_reportes {
    my ($self) = @_;
    mkdir $self->{dir_reportes} unless -d $self->{dir_reportes};
    return $self->{dir_reportes};
}

# ---------------------------------------------------------------
# CARGAR JSON de inventario (formato FASE2)
# Distribuye items segun tipo: MEDICAMENTO, EQUIPO, SUMINISTRO
# ---------------------------------------------------------------
sub cargar_json_inventario {
    my ($self, $ruta) = @_;
    unless (-e $ruta) {
        return (0, 0, "Archivo no encontrado: $ruta");
    }

    eval { require JSON::PP } or do {
        eval { require JSON } or return (0, 0, "Modulo JSON no disponible. Instala con: cpan JSON::PP");
    };

    open my $fh, '<:encoding(UTF-8)', $ruta or return (0, 0, "No se pudo abrir el archivo");
    my $contenido = do { local $/; <$fh> };
    close $fh;

    my $data;
    eval { $data = JSON::PP::decode_json($contenido) };
    if ($@) {
        # intento con JSON si JSON::PP fallo
        eval { $data = JSON::decode_json($contenido) };
        return (0, 0, "Error parseando JSON: $@") if $@;
    }

    my $proveedores_arr = $data->{proveedor} // [];
    my ($insertados, $omitidos) = (0, 0);

    for my $prov_data (@$proveedores_arr) {
        my $nit      = $prov_data->{nit}            // '';
        my $nombre   = $prov_data->{nombre}         // '';
        my $telefono = $prov_data->{telefono}        // '';
        my $dir      = $prov_data->{direccion}       // '';
        my $fecha    = $prov_data->{fecha_entrega}   // '';
        my $factura  = $prov_data->{numero_factura}  // '';

        # Registrar proveedor en la lista circular doble
        my $prov_obj = $self->proveedores->buscar_por_nit($nit);
        unless ($prov_obj) {
            require Proveedor;
            $prov_obj = Proveedor->new({
                nit      => $nit,
                nombre   => $nombre,
                telefono => $telefono,
                direccion => $dir,
            });
            $self->proveedores->agregar($prov_obj);
        }

        my @items_entrega;
        for my $item (@{ $prov_data->{entrega} // [] }) {
            my $tipo    = uc($item->{tipo}    // '');
            my $codigo  = $item->{codigo}     // '';
            my $nom_item = $item->{nombre}    // '';
            my $fab     = $item->{fabricante} // '';
            my $precio  = $item->{precio_unitario} // 0;
            my $cant    = $item->{cantidad}   // 0;
            my $nivel   = $item->{nivel_minimo} // 0;

            unless ($codigo && $cant > 0) { $omitidos++; next }

            push @items_entrega, { tipo => $tipo, codigo => $codigo, cantidad => $cant };

            # Actualizar matriz dispersa: proveedor x fabricante
            $self->matriz->insertar($nombre, $fab, $cant) if $fab;

            if ($tipo eq 'MEDICAMENTO') {
                my $existente = $self->medicamentos->buscar($codigo);
                if ($existente) {
                    $existente->set_cantidad($existente->get_cantidad() + $cant);
                } else {
                    require Medicamento;
                    my $med = Medicamento->new({
                        codigo           => $codigo,
                        nombre           => $nom_item,
                        principioActivo  => $item->{principio_activo} // '',
                        laboratorio      => $fab,
                        precio           => $precio,
                        cantidad         => $cant,
                        fechaVencimiento => $item->{fecha_vencimiento} // '',
                        nivelMinimo      => $nivel,
                    });
                    $self->medicamentos->insertar($med);
                }
                $insertados++;

            } elsif ($tipo eq 'EQUIPO') {
                my $existente = $self->equipos->buscar($codigo);
                if ($existente) {
                    $existente->set_cantidad($existente->get_cantidad() + $cant);
                } else {
                    require Equipo;
                    my $eq = Equipo->new({
                        codigo        => $codigo,
                        nombre        => $nom_item,
                        fabricante    => $fab,
                        precio        => $precio,
                        cantidad      => $cant,
                        fecha_ingreso => $item->{fecha_ingreso} // $fecha,
                        nivel_minimo  => $nivel,
                    });
                    $self->equipos->insertar($eq);
                }
                $insertados++;

            } elsif ($tipo eq 'SUMINISTRO') {
                my $existente = $self->suministros->buscar($codigo);
                if ($existente) {
                    $existente->set_cantidad($existente->get_cantidad() + $cant);
                } else {
                    require Suministro;
                    my $sum = Suministro->new({
                        codigo            => $codigo,
                        nombre            => $nom_item,
                        fabricante        => $fab,
                        precio            => $precio,
                        cantidad          => $cant,
                        fecha_vencimiento => $item->{fecha_vencimiento} // '',
                        nivel_minimo      => $nivel,
                    });
                    $self->suministros->insertar($sum);
                }
                $insertados++;
            } else {
                $omitidos++;
            }
        }

        # Registrar entrega en el historial del proveedor
        $prov_obj->agregar_entrega({
            fecha   => $fecha,
            factura => $factura,
            items   => \@items_entrega,
        }) if @items_entrega;
    }

    return ($insertados, $omitidos, undef);
}

# ---------------------------------------------------------------
# CARGAR JSON de usuarios
# ---------------------------------------------------------------
sub cargar_json_usuarios {
    my ($self, $ruta) = @_;
    unless (-e $ruta) {
        return (0, 0, "Archivo no encontrado: $ruta");
    }

    eval { require JSON::PP } or eval { require JSON };

    open my $fh, '<:encoding(UTF-8)', $ruta or return (0, 0, "No se pudo abrir");
    my $contenido = do { local $/; <$fh> };
    close $fh;

    my $data;
    eval { $data = JSON::PP::decode_json($contenido) };
    if ($@) {
        eval { $data = JSON::decode_json($contenido) };
        return (0, 0, "Error JSON: $@") if $@;
    }

    my ($insertados, $omitidos) = (0, 0);
    require Usuario;

    for my $u (@{ $data->{usuarios} // [] }) {
        my $col  = $u->{numero_colegio}  // '';
        my $nom  = $u->{nombre_completo} // '';
        my $tipo = $u->{tipo_usuario}    // '';
        my $dep  = $u->{departamento}    // '';
        my $esp  = $u->{especialidad}    // '';
        my $pass = $u->{contrasena}      // '';

        unless ($col && $nom && $tipo && $dep) { $omitidos++; next }

        my $usuario = Usuario->new({
            numero_colegio  => $col,
            nombre_completo => $nom,
            tipo_usuario    => $tipo,
            departamento    => $dep,
            especialidad    => $esp,
            contrasena      => $pass,
        });

        my $ok = $self->usuarios->insertar($usuario);
        $ok ? $insertados++ : $omitidos++;
    }

    return ($insertados, $omitidos, undef);
}

1;
