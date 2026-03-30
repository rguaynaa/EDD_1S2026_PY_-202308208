package AdminController;
use strict;
use warnings;

use Estado;
use Medicamento;
use Proveedor;

# ---------------------------------------------------------------
# Obtenemos el estado compartido (singleton)
# ---------------------------------------------------------------
my $estado = Estado->get_instancia();

# ---------------------------------------------------------------
# MENU PRINCIPAL DEL ADMINISTRADOR
# ---------------------------------------------------------------
sub menu {
    my $opcion = '';
    do {
        print "\n" . "=" x 40 . "\n";
        print "       MENU ADMINISTRADOR\n";
        print "=" x 40 . "\n";
        print "1. Registrar medicamento\n";
        print "2. Carga masiva CSV\n";
        print "3. Ver inventario completo\n";
        print "4. Buscar medicamento por codigo\n";
        print "5. Buscar medicamento por nombre\n";
        print "6. Consultar por laboratorio\n";
        print "7. Gestionar proveedores\n";
        print "8. Procesar solicitudes de reabastecimiento\n";
        print "9. Reportes Graphviz\n";
        print "0. Salir\n";
        print "Opcion: ";
        chomp($opcion = <STDIN>);

        if    ($opcion eq '1') { _registrar_medicamento()      }
        elsif ($opcion eq '2') { _cargar_csv()                 }
        elsif ($opcion eq '3') { $estado->inventario->listar() }
        elsif ($opcion eq '4') { _buscar_por_codigo()          }
        elsif ($opcion eq '5') { _buscar_por_nombre()          }
        elsif ($opcion eq '6') { _consultar_laboratorio()      }
        elsif ($opcion eq '7') { _menu_proveedores()           }
        elsif ($opcion eq '8') { _procesar_solicitudes()       }
        elsif ($opcion eq '9') { _menu_reportes()              }
        elsif ($opcion eq '0') { print "Cerrando sesion...\n"  }
        else                   { print "Opcion invalida.\n"    }

    } while ($opcion ne '0');
}

# ---------------------------------------------------------------
# 1. REGISTRAR MEDICAMENTO
# ---------------------------------------------------------------
sub _registrar_medicamento {
    print "\n--- Registrar Medicamento ---\n";

    print "Codigo (ej: MED001): ";
    chomp(my $codigo = <STDIN>);

    print "Nombre comercial: ";
    chomp(my $nombre = <STDIN>);

    print "Principio activo: ";
    chomp(my $principio = <STDIN>);

    print "Laboratorio fabricante: ";
    chomp(my $laboratorio = <STDIN>);

    print "Cantidad en stock: ";
    chomp(my $cantidad = <STDIN>);

    print "Fecha de vencimiento (YYYY-MM-DD): ";
    chomp(my $fecha = <STDIN>);

    print "Precio unitario (Q): ";
    chomp(my $precio = <STDIN>);

    print "Nivel minimo de reorden: ";
    chomp(my $nivel = <STDIN>);

    # Validaciones
    if ($codigo eq '' || $nombre eq '') {
        print "Error: codigo y nombre son obligatorios.\n";
        return;
    }
    unless ($cantidad =~ /^\d+$/ && $nivel =~ /^\d+$/) {
        print "Error: cantidad y nivel minimo deben ser numeros enteros.\n";
        return;
    }
    unless ($precio =~ /^\d+(\.\d+)?$/) {
        print "Error: precio invalido.\n";
        return;
    }

    my $med = Medicamento->new({
        codigo           => $codigo,
        nombre           => $nombre,
        principioActivo  => $principio,
        laboratorio      => $laboratorio,
        cantidad         => $cantidad,
        fechaVencimiento => $fecha,
        precio           => $precio,
        nivelMinimo      => $nivel,
    });

    $estado->inventario->insertar($med);

    # Actualizar matriz dispersa automaticamente
    $estado->matriz->insertar($laboratorio, $nombre, {
        precio    => $precio,
        cantidad  => $cantidad,
        principio => $principio,
    });

    print "Medicamento registrado exitosamente.\n";
}

# ---------------------------------------------------------------
# 2. CARGA MASIVA CSV
# ---------------------------------------------------------------
sub _cargar_csv {
    print "\nRuta del archivo CSV: ";
    chomp(my $ruta = <STDIN>);

    unless (-e $ruta) {
        print "Error: el archivo no existe en: $ruta\n";
        return;
    }

    open my $fh, "<:encoding(UTF-8)", $ruta or do {
        print "No se pudo abrir el archivo.\n";
        return;
    };

    my $linea     = 0;
    my $insertados = 0;
    my $omitidos   = 0;

    while (my $row = <$fh>) {
        chomp $row;
        $row =~ s/\r//g;          # quitar \r de Windows
        $row =~ s/^\x{FEFF}//;    # quitar BOM si existe
        $linea++;

        next if $linea == 1;      # saltar encabezado

        my ($codigo, $nombre, $principio, $laboratorio,
            $precio, $cantidad, $fecha, $nivel) = split /,/, $row;

        # Limpiar espacios
        for ($codigo, $nombre, $principio, $laboratorio,
             $precio, $cantidad, $fecha, $nivel) {
            $_ = _trim($_) if defined $_;
        }

        # Validar campos obligatorios
        unless (defined $codigo && $codigo ne '' &&
                defined $nombre && $nombre ne '' &&
                defined $cantidad && $cantidad =~ /^\d+$/ &&
                defined $precio   && $precio   =~ /^\d+(\.\d+)?$/ &&
                defined $nivel    && $nivel    =~ /^\d+$/) {
            print "Linea $linea omitida: datos invalidos\n";
            $omitidos++;
            next;
        }

        # Evitar duplicados
        if ($estado->inventario->buscar($codigo)) {
            print "Linea $linea omitida: codigo $codigo ya existe\n";
            $omitidos++;
            next;
        }

        my $med = Medicamento->new({
            codigo           => $codigo,
            nombre           => $nombre,
            principioActivo  => $principio  // '',
            laboratorio      => $laboratorio // '',
            precio           => $precio,
            cantidad         => $cantidad,
            fechaVencimiento => $fecha       // '',
            nivelMinimo      => $nivel,
        });

        $estado->inventario->insertar($med);

        # Actualizar matriz dispersa
        $estado->matriz->insertar($laboratorio // '', $nombre, {
            precio    => $precio,
            cantidad  => $cantidad,
            principio => $principio // '',
        });

        $insertados++;
    }

    close $fh;

    print "\nCarga finalizada:\n";
    print "  Insertados : $insertados\n";
    print "  Omitidos   : $omitidos\n";
    print "  Total filas: " . ($linea - 1) . "\n";
}

# ---------------------------------------------------------------
# 4. BUSCAR POR CODIGO
# ---------------------------------------------------------------
sub _buscar_por_codigo {
    print "Codigo: ";
    chomp(my $codigo = <STDIN>);

    my $m = $estado->inventario->buscar($codigo);
    _mostrar_medicamento($m);
}

# ---------------------------------------------------------------
# 5. BUSCAR POR NOMBRE
# ---------------------------------------------------------------
sub _buscar_por_nombre {
    print "Nombre: ";
    chomp(my $nombre = <STDIN>);

    my $m = $estado->inventario->buscar_por_nombre($nombre);
    _mostrar_medicamento($m);
}

# ---------------------------------------------------------------
# 6. CONSULTAR POR LABORATORIO (usa la matriz dispersa)
# ---------------------------------------------------------------
sub _consultar_laboratorio {
    print "Nombre del medicamento a comparar: ";
    chomp(my $med = <STDIN>);
    $estado->matriz->consultar_por_medicamento($med);
}

# ---------------------------------------------------------------
# 7. MENU PROVEEDORES
# ---------------------------------------------------------------
sub _menu_proveedores {
    my $op = '';
    do {
        print "\n--- Gestion de Proveedores ---\n";
        print "1. Registrar proveedor\n";
        print "2. Registrar entrega de proveedor\n";
        print "3. Ver todos los proveedores\n";
        print "0. Volver\n";
        print "Opcion: ";
        chomp($op = <STDIN>);

        if    ($op eq '1') { _registrar_proveedor()  }
        elsif ($op eq '2') { _registrar_entrega()    }
        elsif ($op eq '3') { $estado->proveedores->listar() }
        elsif ($op eq '0') { }
        else               { print "Opcion invalida.\n" }
    } while ($op ne '0');
}

sub _registrar_proveedor {
    print "\n--- Nuevo Proveedor ---\n";
    print "NIT: ";          chomp(my $nit  = <STDIN>);
    print "Nombre: ";       chomp(my $nom  = <STDIN>);
    print "Contacto: ";     chomp(my $con  = <STDIN>);
    print "Telefono: ";     chomp(my $tel  = <STDIN>);
    print "Direccion: ";    chomp(my $dir  = <STDIN>);

    if ($nit eq '' || $nom eq '') {
        print "Error: NIT y nombre son obligatorios.\n";
        return;
    }

    my $prov = Proveedor->new({
        nit      => $nit,
        nombre   => $nom,
        contacto => $con,
        telefono => $tel,
        direccion => $dir,
    });

    my $ok = $estado->proveedores->agregar($prov);
    print $ok ? "Proveedor registrado.\n" : "Error: NIT ya registrado.\n";
}

sub _registrar_entrega {
    print "\nNIT del proveedor: ";
    chomp(my $nit = <STDIN>);

    my $prov = $estado->proveedores->buscar_por_nit($nit);
    unless ($prov) {
        print "Proveedor no encontrado.\n";
        return;
    }

    print "Fecha de entrega (YYYY-MM-DD): "; chomp(my $fecha   = <STDIN>);
    print "Numero de factura: ";              chomp(my $factura = <STDIN>);
    print "Codigo de medicamento: ";          chomp(my $cod_med = <STDIN>);
    print "Cantidad entregada: ";             chomp(my $cant    = <STDIN>);

    unless ($cant =~ /^\d+$/) {
        print "Cantidad invalida.\n";
        return;
    }

    # Registrar entrega en el proveedor
    $prov->agregar_entrega({
        fecha     => $fecha,
        factura   => $factura,
        codigo_med => $cod_med,
        cantidad  => $cant,
    });

    # Actualizar stock en el inventario
    my $med = $estado->inventario->buscar($cod_med);
    if ($med) {
        my $nueva_cant = $med->get_cantidad() + $cant;
        $med->set_cantidad($nueva_cant);
        print "Stock actualizado. Nueva cantidad: $nueva_cant\n";
    } else {
        print "Advertencia: medicamento $cod_med no encontrado en inventario.\n";
    }

    print "Entrega registrada para: " . $prov->get_nombre() . "\n";
}

# ---------------------------------------------------------------
# 8. PROCESAR SOLICITUDES
# ---------------------------------------------------------------
sub _procesar_solicitudes {
    if ($estado->solicitudes->esta_vacia()) {
        print "No hay solicitudes pendientes.\n";
        return;
    }

    my $op = '';
    do {
        my $s = $estado->solicitudes->ver_primera();
        unless ($s) { last }

        print "\n--- Solicitud Pendiente ---\n";
        print $s->to_string() . "\n";
        print "Total pendientes: " . $estado->solicitudes->get_tamanio() . "\n";
        print "\n1. Aprobar\n2. Rechazar\n0. Volver\nOpcion: ";
        chomp($op = <STDIN>);

        if ($op eq '1') {
            # Verificar stock suficiente
            my $med = $estado->inventario->buscar($s->get_codigo_med());
            if (!$med) {
                print "Medicamento no encontrado en inventario.\n";
            } elsif ($med->get_cantidad() < $s->get_cantidad()) {
                print "Stock insuficiente. Disponible: " . $med->get_cantidad() . "\n";
            } else {
                my $nueva_cant = $med->get_cantidad() - $s->get_cantidad();
                $med->set_cantidad($nueva_cant);
                $s->set_estado('aprobada');
                $estado->solicitudes->eliminar_primera();
                print "Solicitud aprobada. Stock actualizado: $nueva_cant\n";
            }
        } elsif ($op eq '2') {
            $s->set_estado('rechazada');
            $estado->solicitudes->eliminar_primera();
            print "Solicitud rechazada y eliminada.\n";
        } elsif ($op eq '0') {
            # volver
        } else {
            print "Opcion invalida.\n";
        }

    } while ($op ne '0' && !$estado->solicitudes->esta_vacia());

    print "No quedan solicitudes pendientes.\n" if $estado->solicitudes->esta_vacia();
}

# ---------------------------------------------------------------
# 9. MENU REPORTES
# ---------------------------------------------------------------
sub _menu_reportes {
    my $op = '';
    do {
        print "\n--- Reportes Graphviz ---\n";
        print "1. Reporte inventario (lista doble)\n";
        print "2. Reporte solicitudes (lista circular doble)\n";
        print "3. Reporte proveedores (lista circular)\n";
        print "4. Reporte matriz dispersa\n";
        print "0. Volver\n";
        print "Opcion: ";
        chomp($op = <STDIN>);

        if ($op eq '1') {
            $estado->inventario->generar_dot("reporte_inventario.dot");
        } elsif ($op eq '2') {
            $estado->solicitudes->generar_dot("reporte_solicitudes.dot");
        } elsif ($op eq '3') {
            $estado->proveedores->generar_dot("reporte_proveedores.dot");
        } elsif ($op eq '4') {
            $estado->matriz->generar_dot("reporte_matriz.dot");
        } elsif ($op eq '0') { }
        else { print "Opcion invalida.\n" }

    } while ($op ne '0');
}

# ---------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------
sub _mostrar_medicamento {
    my ($m) = @_;
    if (!$m) {
        print "Medicamento no encontrado.\n";
        return;
    }
    print "\n" . $m->to_string() . "\n";
}

sub _trim {
    my ($v) = @_;
    return '' unless defined $v;
    $v =~ s/^\s+|\s+$//g;
    return $v;
}

1;
