package AdminController;
use strict;
use warnings;
use Inventario;
use Medicamento;
use Text::CSV;

my $inventario = Inventario->new();

sub menu_admin{
    print "\n=== Menu Administrador ===\n";
    print "1. Registrar Medicamentos\n";
    print "2. Ver Inventrario\n";
    print "3. Buscar medicamento por codigo\n";
    print "4. Buscar medicamento por nombre\n";
    print "5. Ver inventario por laboratorio\n";
    print "6. Carga masiva CSV\n";
    print "0. Volver al menu principal\n";
    print "Seleccione una opcion: ";


    chomp(my $opcion = <STDIN>);
    if ($opcion == 1) {
        registrar_medicamento();
    }elsif ($opcion == 2) {
        print "Ver Inventario\n";
        $inventario->listar();
    }elsif ($opcion == 3) {
        print "Codigo: ";
        chomp(my $c = <STDIN>);
        my $me=$inventario-> Buscar($c);
        mostrar_medicamento($me);
    }elsif ($opcion == 4) {
        print "Nombre: ";
        chomp(my $n = <STDIN>);
        my $me=$inventario-> Buscar_por_nombre($n);
        mostrar_medicamento($me);
    
    }elsif ($opcion == 5) {
        print "Laboratorio: ";
        chomp(my $l = <STDIN>);
        $inventario->listar_por_laboratorio($l);
    }elsif ($opcion == 6) {
        cargar_csv();
    }elsif ($opcion == 0) {
        print "Volviendo al menu principal...\n";
    }else {
        print "Opcion invalida\n";
    }
    
}

sub registrar_medicamento {
    print "\n--- Registro de Medicamento ---\n";

    print "Codigo: ";
    chomp(my $codigo = <STDIN>);

    print "Nombre comercial: ";
    chomp(my $nombre = <STDIN>);

    print "Principio activo: ";
    chomp(my $principio = <STDIN>);

    print "Laboratorio: ";
    chomp(my $laboratorio = <STDIN>);

    print "Cantidad en stock: ";
    chomp(my $cantidad = <STDIN>);

    print "Fecha de vencimiento (YYYY-MM-DD): ";
    chomp(my $fecha = <STDIN>);

    print "Precio unitario: ";
    chomp(my $precio = <STDIN>);

    print "Nivel minimo de reorden: ";
    chomp(my $nivel = <STDIN>);

    # Validaciones básicas
    if ($codigo eq "" || $nombre eq "" || $cantidad !~ /^\d+$/) {
        print "Datos invalidos. Operacion cancelada.\n";
        return;
    }

    # Evitar medicamentos duplicados
    if ($inventario->buscar($codigo)) {
        print "Error: ya existe un medicamento con ese codigo.\n";
        return;
    }

    my $me = Medicamento->new({
        codigo           => $codigo,
        nombre           => $nombre,
        principioActivo  => $principio,
        laboratorio      => $laboratorio,
        cantidad         => $cantidad,
        fechaVencimiento => $fecha,
        precio           => $precio,
        nivelMinimo      => $nivel
    });

    $inventario->insertar($me);

    print "Medicamento registrado exitosamente.\n";
}

sub mostrar_medicamento {
    my ($m) = @_;

    if (!$m) {
        print "Medicamento no encontrado.\n";
        return;
    }

    print "\n--- MEDICAMENTO ---\n";
    print "Codigo: ", $m->get_codigo(), "\n";
    print "Nombre: ", $m->get_nombre(), "\n";
    print "Principio activo: ", $m->get_principioActivo(), "\n";
    print "Laboratorio: ", $m->get_laboratorio(), "\n";
    print "Cantidad: ", $m->get_cantidad(), "\n";
    print "Precio: Q", $m->get_precio(), "\n";
    print "Vence: ", $m->get_fechaVencimiento(), "\n";

    if ($m->bajo_stock()) {
        print "⚠ ALERTA: Bajo stock\n";
    }
}



sub trim {
    my ($v) = @_;
    return "" unless defined $v;
    $v =~ s/^\s+|\s+$//g;
    $v =~ s/\x{FEFF}//g; # BOM
    return $v;
}

sub cargar_csv {
    print "\nRuta del archivo CSV: ";
    chomp(my $ruta = <STDIN>);

    unless (-e $ruta) {
        print "Error: el archivo no existe.\n";
        return;
    }

    open my $fh, "<", $ruta or do {
        print "No se pudo abrir el archivo.\n";
        return;
    };

    my $csv = Text::CSV->new({
        binary    => 1,
        auto_diag => 1,
        sep_char  => ','
    });

    my $linea = 0;
    my $insertados = 0;
    my $omitidos = 0;

    while (my $row = $csv->getline($fh)) {
        $linea++;
        next if $linea == 1; # encabezado

        my (
            $codigo,
            $nombre,
            $principio,
            $laboratorio,
            $precio,
            $cantidad,
            $fecha,
            $nivel
        ) = map { trim($_) } @$row;

        # Validaciones
        unless (
            $codigo &&
            $nombre &&
            $cantidad =~ /^\d+$/ &&
            $precio   =~ /^\d+(\.\d+)?$/ &&
            $nivel    =~ /^\d+$/
        ) {
            $omitidos++;
            next;
        }

        if ($inventario->buscar($codigo)) {
            $omitidos++;
            next;
        }

        my $me = Medicamento->new({
            codigo           => $codigo,
            nombre           => $nombre,
            principioActivo  => $principio,
            laboratorio      => $laboratorio,
            precio           => $precio,
            cantidad         => $cantidad,
            fechaVencimiento => $fecha,
            nivelMinimo      => $nivel
        });

        $inventario->insertar($me);
        $insertados++;
    }

    close $fh;

    print "\nCarga CSV finalizada\n";
    print "Insertados: $insertados\n";
    print "Omitidos:   $omitidos\n";
}

1;
