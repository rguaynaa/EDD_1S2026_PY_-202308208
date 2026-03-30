package UsuarioController;
use strict;
use warnings;

use Estado;
use Solicitud;

my $estado = Estado->get_instancia();

# Usuarios hardcodeados por departamento
# En Fase 2 esto pasara al arbol AVL
my %USUARIOS = (
    'DEP-MED' => 'med2026',
    'DEP-CIR' => 'cir2026',
    'DEP-LAB' => 'lab2026',
    'DEP-FAR' => 'far2026',
);

# ---------------------------------------------------------------
# LOGIN de usuario departamental
# ---------------------------------------------------------------
sub login {
    print "\n--- Inicio de Sesion Usuario Departamental ---\n";
    print "Codigo de departamento (DEP-MED/CIR/LAB/FAR): ";
    chomp(my $dep = <STDIN>);

    print "Contrasena: ";
    chomp(my $pass = <STDIN>);

    unless (exists $USUARIOS{$dep} && $USUARIOS{$dep} eq $pass) {
        print "Credenciales incorrectas.\n";
        return 0;
    }

    $estado->set_usuario_actual({ departamento => $dep });
    print "Bienvenido, departamento $dep\n";
    return 1;
}

# ---------------------------------------------------------------
# MENU PRINCIPAL DEL USUARIO
# ---------------------------------------------------------------
sub menu {
    # Pedir login primero
    return unless login();

    my $dep    = $estado->get_usuario_actual()->{departamento};
    my $opcion = '';

    do {
        print "\n" . "=" x 40 . "\n";
        print "  MENU USUARIO - $dep\n";
        print "=" x 40 . "\n";
        print "1. Consultar disponibilidad de medicamento\n";
        print "2. Solicitar reabastecimiento\n";
        print "3. Ver historial de mis solicitudes\n";
        print "0. Salir\n";
        print "Opcion: ";
        chomp($opcion = <STDIN>);

        if    ($opcion eq '1') { _consultar_medicamento()  }
        elsif ($opcion eq '2') { _solicitar_reabastecimiento($dep) }
        elsif ($opcion eq '3') { _ver_historial($dep)      }
        elsif ($opcion eq '0') { 
            $estado->set_usuario_actual(undef);
            print "Sesion cerrada.\n";
        }
        else { print "Opcion invalida.\n" }

    } while ($opcion ne '0');
}

# ---------------------------------------------------------------
# 1. CONSULTAR DISPONIBILIDAD
# ---------------------------------------------------------------
sub _consultar_medicamento {
    print "\n1. Buscar por codigo\n2. Buscar por nombre\nOpcion: ";
    chomp(my $op = <STDIN>);

    my $m;
    if ($op eq '1') {
        print "Codigo: ";
        chomp(my $codigo = <STDIN>);
        $m = $estado->inventario->buscar($codigo);
    } elsif ($op eq '2') {
        print "Nombre: ";
        chomp(my $nombre = <STDIN>);
        $m = $estado->inventario->buscar_por_nombre($nombre);
    } else {
        print "Opcion invalida.\n";
        return;
    }

    unless ($m) {
        print "Medicamento no disponible.\n";
        return;
    }

    print "\nNombre    : " . $m->get_nombre()           . "\n";
    print "Disponible: " . $m->get_cantidad()           . " unidades\n";
    print "Vence     : " . $m->get_fechaVencimiento()   . "\n";

    if ($m->bajo_stock()) {
        print "⏳ Stock bajo - en proceso de reabastecimiento\n";
    } else {
        print "✓ Stock normal\n";
    }
}

# ---------------------------------------------------------------
# 2. SOLICITAR REABASTECIMIENTO
# ---------------------------------------------------------------
sub _solicitar_reabastecimiento {
    my ($dep) = @_;

    print "\n--- Nueva Solicitud de Reabastecimiento ---\n";
    print "Codigo del medicamento: ";
    chomp(my $codigo = <STDIN>);

    # Verificar que el medicamento existe
    unless ($estado->inventario->buscar($codigo)) {
        print "Medicamento no encontrado en el inventario.\n";
        return;
    }

    print "Cantidad requerida: ";
    chomp(my $cantidad = <STDIN>);

    unless ($cantidad =~ /^\d+$/ && $cantidad > 0) {
        print "Cantidad invalida.\n";
        return;
    }

    print "Prioridad (urgente/alta/media/baja): ";
    chomp(my $prioridad = <STDIN>);
    $prioridad = 'media' unless $prioridad =~ /^(urgente|alta|media|baja)$/;

    print "Justificacion: ";
    chomp(my $just = <STDIN>);

    my $solicitud = Solicitud->new({
        departamento  => $dep,
        codigo_med    => $codigo,
        cantidad      => $cantidad,
        prioridad     => $prioridad,
        justificacion => $just,
    });

    # Agregar a la lista circular doble de pendientes
    $estado->solicitudes->agregar($solicitud);

    # Guardar en historial del departamento
    $estado->agregar_historial($solicitud);

    print "Solicitud #" . $solicitud->get_numero() . " creada exitosamente.\n";
}

# ---------------------------------------------------------------
# 3. VER HISTORIAL DE SOLICITUDES DEL DEPARTAMENTO
# ---------------------------------------------------------------
sub _ver_historial {
    my ($dep) = @_;

    my $historial = $estado->get_historial($dep);

    if (!@$historial) {
        print "No hay solicitudes registradas para $dep.\n";
        return;
    }

    print "\n--- Historial de Solicitudes: $dep ---\n";
    for my $s (@$historial) {
        print $s->to_string() . "\n";
    }
    print "Total: " . scalar(@$historial) . " solicitudes.\n";
}

1;
