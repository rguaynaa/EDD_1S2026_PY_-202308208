package EstadoF3;
use strict;
use warnings;

# ============================================================
# EstadoF3 - Singleton que hereda/extiende Estado de Fase 2
# Agrega: Grafo, TablaHash, ListaSolicitudes, ArbolMerkle, LZW
# ============================================================

use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/model";

use ListaDoble;
use ListaCircularDoble;
use MatrizDispersa;
use ArbolBST;
use ArbolAVL;
use ArbolB;
use Grafo;
use TablaHash;
use ListaSolicitudes;
use ArbolMerkle;
use LZW;

my $instancia;

sub get_instancia {
    my ($class) = @_;
    unless (defined $instancia) {
        $instancia = bless {
            # --- Estructuras F2 ---
            medicamentos   => ListaDoble->new(),
            equipos        => ArbolBST->new(),
            suministros    => ArbolB->new(),
            usuarios       => ArbolAVL->new(),
            proveedores    => ListaCircularDoble->new(),
            matriz         => MatrizDispersa->new(),

            # --- Estructuras F3 ---
            grafo          => Grafo->new(),
            tabla_hash     => TablaHash->new(),
            solicitudes    => ListaSolicitudes->new(),
            merkle         => ArbolMerkle->new(),

            # --- Sesion ---
            usuario_actual => undef,
            es_admin       => 0,

            # --- Chats en memoria: { "col_a|col_b" => [ {ts,remit,cont}, ... ] } ---
            chats          => {},

            # --- Directorios ---
            dir_reportes   => 'reports',
            dir_chats      => 'chats',
        }, $class;
    }
    return $instancia;
}

# --- Accessors F2 ---
sub medicamentos { $_[0]->{medicamentos} }
sub equipos      { $_[0]->{equipos}      }
sub suministros  { $_[0]->{suministros}  }
sub usuarios     { $_[0]->{usuarios}     }
sub proveedores  { $_[0]->{proveedores}  }
sub matriz       { $_[0]->{matriz}       }

# --- Accessors F3 ---
sub grafo       { $_[0]->{grafo}       }
sub tabla_hash  { $_[0]->{tabla_hash}  }
sub solicitudes { $_[0]->{solicitudes} }
sub merkle      { $_[0]->{merkle}      }
sub chats       { $_[0]->{chats}       }

# --- Sesion ---
sub get_usuario_actual { $_[0]->{usuario_actual} }
sub set_usuario_actual { $_[0]->{usuario_actual} = $_[1] }
sub get_es_admin       { $_[0]->{es_admin}       }
sub set_es_admin       { $_[0]->{es_admin}       = $_[1] }

sub dir_reportes {
    my ($self) = @_;
    mkdir $self->{dir_reportes} unless -d $self->{dir_reportes};
    return $self->{dir_reportes};
}

sub dir_chats {
    my ($self) = @_;
    mkdir $self->{dir_chats} unless -d $self->{dir_chats};
    return $self->{dir_chats};
}

# ---------------------------------------------------------------
# CLAVE de conversacion (par ordenado)
# ---------------------------------------------------------------
sub clave_chat {
    my ($self, $a, $b) = @_;
    return join('|', sort($a, $b));
}

# ---------------------------------------------------------------
# AGREGAR MENSAJE al historial en memoria
# ---------------------------------------------------------------
sub agregar_mensaje {
    my ($self, $remitente, $receptor, $contenido) = @_;
    my $clave = $self->clave_chat($remitente, $receptor);
    $self->{chats}{$clave} //= [];
    my @t = localtime(time);
    my $ts = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
    push @{ $self->{chats}{$clave} }, {
        timestamp  => $ts,
        remitente  => $remitente,
        contenido  => $contenido,
    };
}

# ---------------------------------------------------------------
# CARGAR chats del usuario al iniciar sesion
# ---------------------------------------------------------------
sub cargar_chats_usuario {
    my ($self, $col) = @_;
    my $chats_cargados = LZW->cargar_chats_usuario($col, $self->{dir_chats});
    # Mergear con chats en memoria (no pisar mensajes nuevos)
    for my $clave (keys %$chats_cargados) {
        unless (exists $self->{chats}{$clave}) {
            $self->{chats}{$clave} = $chats_cargados->{$clave};
        }
    }
}

# ---------------------------------------------------------------
# GUARDAR chats del usuario al cerrar sesion
# ---------------------------------------------------------------
sub guardar_chats_usuario {
    my ($self, $col) = @_;
    # Solo guardar conversaciones donde participa este usuario
    my %mis_chats;
    for my $clave (keys %{ $self->{chats} }) {
        my ($a, $b) = split /\|/, $clave;
        if ($a eq $col || $b eq $col) {
            $mis_chats{$clave} = $self->{chats}{$clave};
        }
    }
    LZW->guardar_chats_usuario($col, \%mis_chats, $self->{dir_chats});
}

# ---------------------------------------------------------------
# INSERTAR USUARIO en AVL + TablaHash + Grafo
# ---------------------------------------------------------------
sub registrar_usuario {
    my ($self, $usuario) = @_;
    my $ok = $self->usuarios->insertar($usuario);
    if ($ok) {
        $self->tabla_hash->insertar($usuario);
        $self->grafo->agregar_nodo($usuario->get_numero_colegio());
    }
    return $ok;
}

# ---------------------------------------------------------------
# ELIMINAR USUARIO de AVL + TablaHash + Grafo
# ---------------------------------------------------------------
sub eliminar_usuario {
    my ($self, $col) = @_;
    my $ok = $self->usuarios->eliminar($col);
    if ($ok) {
        $self->tabla_hash->eliminar($col);
        $self->grafo->eliminar_nodo($col);
    }
    return $ok;
}

# ---------------------------------------------------------------
# AGREGAR SOLICITUD a la lista + Merkle
# ---------------------------------------------------------------
sub agregar_solicitud {
    my ($self, $sol) = @_;
    $self->solicitudes->agregar($sol);
    $self->merkle->agregar_solicitud($sol);
    return 1;
}

# ---------------------------------------------------------------
# APROBAR solicitud
# ---------------------------------------------------------------
sub aprobar_solicitud {
    my ($self) = @_;
    my $sol = $self->solicitudes->primera();
    return (0, "No hay solicitudes pendientes.") unless $sol;

    my $tipo  = $sol->get_tipo_item();
    my $cod   = $sol->get_codigo();
    my $cant  = $sol->get_cantidad();

    # Verificar stock
    my ($item, $stock_actual);
    if ($tipo eq 'MEDICAMENTO') {
        $item = $self->medicamentos->buscar($cod);
    } elsif ($tipo eq 'EQUIPO') {
        $item = $self->equipos->buscar($cod);
    } elsif ($tipo eq 'SUMINISTRO') {
        $item = $self->suministros->buscar($cod);
    }

    unless (defined $item) {
        return (0, "Item '$cod' no encontrado en inventario.");
    }

    $stock_actual = $item->get_cantidad();
    if ($stock_actual < $cant) {
        return (0, "Stock insuficiente. Disponible: $stock_actual, Solicitado: $cant");
    }

    $item->set_cantidad($stock_actual - $cant);
    $sol->set_estado('APROBADA');
    $self->solicitudes->eliminar_primera();
    return (1, "Solicitud aprobada. Stock actualizado: " . ($stock_actual - $cant));
}

# ---------------------------------------------------------------
# RECHAZAR solicitud
# ---------------------------------------------------------------
sub rechazar_solicitud {
    my ($self) = @_;
    my $sol = $self->solicitudes->primera();
    return 0 unless $sol;
    $sol->set_estado('RECHAZADA');
    $self->solicitudes->eliminar_primera();
    return 1;
}

# ---------------------------------------------------------------
# ASIGNAR DEPARTAMENTO a usuario (actualiza AVL, TablaHash, Grafo)
# ---------------------------------------------------------------
sub asignar_departamento {
    my ($self, $col, $dep) = @_;
    my $u = $self->usuarios->buscar($col);
    return 0 unless $u;

    # Actualizar en TablaHash (re-insertar con nuevo tipo)
    $self->tabla_hash->eliminar($col);
    $u->{departamento} = $dep;
    $self->tabla_hash->insertar($u);
    return 1;
}

# ---------------------------------------------------------------
# CARGAR JSON INVENTARIO (igual que F2)
# ---------------------------------------------------------------
sub cargar_json_inventario {
    my ($self, $ruta) = @_;
    unless (-e $ruta) { return (0, 0, "Archivo no encontrado: $ruta") }

    open my $fh, '<:encoding(UTF-8)', $ruta or return (0, 0, "No se pudo abrir");
    my $contenido = do { local $/; <$fh> };
    close $fh;

    require JSON::PP;
    my $data;
    eval { $data = JSON::PP->new->decode($contenido) };
    return (0, 0, "Error JSON: $@") if $@;

    my ($insertados, $omitidos) = (0, 0);

    for my $prov_data (@{ $data->{proveedor} // [] }) {
        my $nit    = $prov_data->{nit}    // '';
        my $nombre = $prov_data->{nombre} // '';
        my $tel    = $prov_data->{telefono}  // '';
        my $dir    = $prov_data->{direccion} // '';
        my $fecha  = $prov_data->{fecha_entrega}  // '';
        my $factura= $prov_data->{numero_factura} // '';

        my $prov_obj = $self->proveedores->buscar_por_nit($nit);
        unless ($prov_obj) {
            require Proveedor;
            $prov_obj = Proveedor->new({ nit=>$nit, nombre=>$nombre, telefono=>$tel, direccion=>$dir });
            $self->proveedores->agregar($prov_obj);
        }

        my @items_entrega;
        for my $item (@{ $prov_data->{entrega} // [] }) {
            my $tipo   = uc($item->{tipo}          // '');
            my $codigo = $item->{codigo}            // '';
            my $nom    = $item->{nombre}            // '';
            my $fab    = $item->{fabricante}        // '';
            my $precio = $item->{precio_unitario}   // 0;
            my $cant   = $item->{cantidad}          // 0;
            my $nivel  = $item->{nivel_minimo}      // 0;

            unless ($codigo && $cant > 0) { $omitidos++; next }
            push @items_entrega, { tipo=>$tipo, codigo=>$codigo, cantidad=>$cant };

            $self->matriz->insertar($nombre, $fab, $cant) if $fab;

            if ($tipo eq 'MEDICAMENTO') {
                my $ex = $self->medicamentos->buscar($codigo);
                if ($ex) { $ex->set_cantidad($ex->get_cantidad() + $cant) }
                else {
                    require Medicamento;
                    $self->medicamentos->insertar(Medicamento->new({
                        codigo=>$codigo, nombre=>$nom, principioActivo=>$item->{principio_activo}//'',
                        laboratorio=>$fab, precio=>$precio, cantidad=>$cant,
                        fechaVencimiento=>$item->{fecha_vencimiento}//'', nivelMinimo=>$nivel,
                    }));
                }
                $insertados++;
            } elsif ($tipo eq 'EQUIPO') {
                my $ex = $self->equipos->buscar($codigo);
                if ($ex) { $ex->set_cantidad($ex->get_cantidad() + $cant) }
                else {
                    require Equipo;
                    $self->equipos->insertar(Equipo->new({
                        codigo=>$codigo, nombre=>$nom, fabricante=>$fab, precio=>$precio,
                        cantidad=>$cant, fecha_ingreso=>$item->{fecha_ingreso}//$fecha, nivel_minimo=>$nivel,
                    }));
                }
                $insertados++;
            } elsif ($tipo eq 'SUMINISTRO') {
                my $ex = $self->suministros->buscar($codigo);
                if ($ex) { $ex->set_cantidad($ex->get_cantidad() + $cant) }
                else {
                    require Suministro;
                    $self->suministros->insertar(Suministro->new({
                        codigo=>$codigo, nombre=>$nom, fabricante=>$fab, precio=>$precio,
                        cantidad=>$cant, fecha_vencimiento=>$item->{fecha_vencimiento}//'', nivel_minimo=>$nivel,
                    }));
                }
                $insertados++;
            } else { $omitidos++ }
        }
        $prov_obj->agregar_entrega({ fecha=>$fecha, factura=>$factura, items=>\@items_entrega }) if @items_entrega;
    }
    return ($insertados, $omitidos, undef);
}

# ---------------------------------------------------------------
# CARGAR JSON USUARIOS (F3: soporta departamento null -> SIN-DEP)
# ---------------------------------------------------------------
sub cargar_json_usuarios {
    my ($self, $ruta) = @_;
    unless (-e $ruta) { return (0, 0, "Archivo no encontrado: $ruta") }

    open my $fh, '<:encoding(UTF-8)', $ruta or return (0, 0, "No se pudo abrir");
    my $contenido = do { local $/; <$fh> };
    close $fh;

    require JSON::PP;
    my $data;
    eval { $data = JSON::PP->new->decode($contenido) };
    return (0, 0, "Error JSON: $@") if $@;

    my ($insertados, $omitidos) = (0, 0);
    require Usuario;

    for my $u (@{ $data->{usuarios} // [] }) {
        my $col  = $u->{numero_colegio}  // '';
        my $nom  = $u->{nombre_completo} // '';
        my $tipo = $u->{tipo_usuario}    // '';
        my $dep  = $u->{departamento}    // 'SIN-DEP';   # null -> SIN-DEP
        $dep = 'SIN-DEP' unless defined $dep && $dep;
        my $esp  = $u->{especialidad}    // '';
        my $pass = $u->{contrasena}      // '';

        unless ($col && $nom && $tipo) { $omitidos++; next }

        my $usuario = Usuario->new({
            numero_colegio  => $col,
            nombre_completo => $nom,
            tipo_usuario    => $tipo,
            departamento    => $dep,
            especialidad    => $esp,
            contrasena      => $pass,
        });

        my $ok = $self->registrar_usuario($usuario);
        $ok ? $insertados++ : $omitidos++;
    }
    return ($insertados, $omitidos, undef);
}

# ---------------------------------------------------------------
# CARGAR JSON RELACIONES DE COLABORACION (grafo)
# ---------------------------------------------------------------
sub cargar_json_relaciones {
    my ($self, $ruta) = @_;
    unless (-e $ruta) { return (0, 0, "Archivo no encontrado: $ruta") }

    open my $fh, '<:encoding(UTF-8)', $ruta or return (0, 0, "No se pudo abrir");
    my $contenido = do { local $/; <$fh> };
    close $fh;

    require JSON::PP;
    my $data;
    eval { $data = JSON::PP->new->decode($contenido) };
    return (0, 0, "Error JSON: $@") if $@;

    my ($activas, $pendientes, $rechazadas) = (0, 0, 0);

    for my $rel (@{ $data // [] }) {
        my $sol    = $rel->{solicitante} // '';
        my $rec    = $rel->{receptor}    // '';
        my $estado = uc($rel->{estado}  // '');

        next unless $sol && $rec;

        if ($estado eq 'ACTIVA') {
            $self->grafo->agregar_nodo($sol);
            $self->grafo->agregar_nodo($rec);
            $self->grafo->agregar_arista($sol, $rec);
            $activas++;
        } elsif ($estado eq 'PENDIENTE') {
            $self->grafo->agregar_nodo($sol);
            $self->grafo->agregar_nodo($rec);
            $self->grafo->agregar_solicitud($sol, $rec);
            $pendientes++;
        } else {
            $rechazadas++;
        }
    }
    return ($activas, $pendientes, "Rechazadas: $rechazadas");
}

1;
