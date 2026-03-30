package VentanaLogin;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Gtk3 -init;



use Estado;

# Credenciales del administrador (segun enunciado)
use constant ADMIN_USER => 'AdminHospital';
use constant ADMIN_PASS => 'MedTrack2025';

sub nueva {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->_construir();
    return $self;
}

sub _construir {
    my ($self) = @_;

    # Ventana principal
    $self->{ventana} = Gtk3::Window->new('toplevel');
    $self->{ventana}->set_title('EDD MedTrack F2 EST');
    $self->{ventana}->set_default_size(480, 420);
    $self->{ventana}->set_position('center');
    $self->{ventana}->set_resizable(0);
    $self->{ventana}->signal_connect(destroy => sub { Gtk3->main_quit });

    # Aplicar CSS
    my $css = Gtk3::CssProvider->new();
    $css->load_from_data('
        window { background-color: #1a2744; }
        .header { background-color: #1a2744; color: white; font-size: 18px; font-weight: bold; }
        .btn-login { background-color: #e67e22; color: white; font-size: 13px; border-radius: 6px; }
        .btn-login:hover { background-color: #d35400; }
        .entry-field { border-radius: 4px; padding: 6px; font-size: 12px; }
        .tab-label { font-size: 12px; }
        notebook tab { background-color: #2c3e6b; color: white; padding: 6px 12px; }
        notebook tab:checked { background-color: #e67e22; }
    ');
    my $screen = Gtk3::Gdk::Screen::get_default();
Gtk3::StyleContext::add_provider_for_screen(
    $screen,
    $css,
    Gtk3::STYLE_PROVIDER_PRIORITY_APPLICATION
);

    # Layout principal
    my $vbox = Gtk3::Box->new('vertical', 0);
    $self->{ventana}->add($vbox);

    # Header
    my $header = Gtk3::Label->new('EDD MEDTRACK');
    $header->get_style_context()->add_class('header');
    $header->set_margin_top(15);
    $header->set_margin_bottom(5);
    $vbox->pack_start($header, 0, 0, 0);

    # Notebook con 3 tabs
    my $notebook = Gtk3::Notebook->new();
    $notebook->set_margin_start(20);
    $notebook->set_margin_end(20);
    $notebook->set_margin_bottom(15);
    $vbox->pack_start($notebook, 1, 1, 0);

    # Tab 1: Login
    $notebook->append_page($self->_tab_login(), Gtk3::Label->new('Iniciar Sesión'));

    # Tab 2: Registro
    $notebook->append_page($self->_tab_registro(), Gtk3::Label->new('Registro'));

    # Tab 3: Información
    $notebook->append_page($self->_tab_info(), Gtk3::Label->new('Información'));

    $self->{ventana}->show_all();
}

# ---------------------------------------------------------------
# TAB 1: LOGIN
# ---------------------------------------------------------------
sub _tab_login {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_margin_start(40);
    $vbox->set_margin_end(40);
    $vbox->set_margin_top(20);
    $vbox->set_margin_bottom(20);

    # Logo placeholder
    my $logo = Gtk3::Label->new('🏥 Hospital General San Carlos');
    $logo->set_markup('<span foreground="white" size="large">🏥 Hospital General San Carlos</span>');
    $vbox->pack_start($logo, 0, 0, 8);

    my $lbl_login = Gtk3::Label->new('');
    $lbl_login->set_markup('<span foreground="white" size="large" weight="bold">LOGIN</span>');
    $vbox->pack_start($lbl_login, 0, 0, 4);

    # Campo usuario
    my $lbl_user = Gtk3::Label->new('');
    $lbl_user->set_markup('<span foreground="white">USUARIO</span>');
    $lbl_user->set_halign('start');
    $vbox->pack_start($lbl_user, 0, 0, 0);

    $self->{entry_user} = Gtk3::Entry->new();
    $self->{entry_user}->set_placeholder_text('Número de colegio o AdminHospital');
    $vbox->pack_start($self->{entry_user}, 0, 0, 2);

    # Campo contraseña
    my $lbl_pass = Gtk3::Label->new('');
    $lbl_pass->set_markup('<span foreground="white">CONTRASEÑA</span>');
    $lbl_pass->set_halign('start');
    $vbox->pack_start($lbl_pass, 0, 0, 0);

    $self->{entry_pass} = Gtk3::Entry->new();
    $self->{entry_pass}->set_visibility(0);
    $self->{entry_pass}->set_placeholder_text('Contraseña');
    $vbox->pack_start($self->{entry_pass}, 0, 0, 4);

    # Mensaje de error
    $self->{lbl_error} = Gtk3::Label->new('');
    $self->{lbl_error}->set_markup('<span foreground="#e74c3c"></span>');
    $vbox->pack_start($self->{lbl_error}, 0, 0, 0);

    # Boton login
    my $btn = Gtk3::Button->new('Iniciar Sesión');
    $btn->get_style_context()->add_class('btn-login');
    $btn->signal_connect(clicked => sub { $self->_hacer_login() });
    $vbox->pack_start($btn, 0, 0, 4);

    # Enter en campo contraseña también hace login
    $self->{entry_pass}->signal_connect(activate => sub { $self->_hacer_login() });

    # Link a registro
    my $link = Gtk3::Label->new('');
    $link->set_markup('<span foreground="#aaaaaa">¿Aún no tienes cuenta? Usa la pestaña Registro</span>');
    $vbox->pack_start($link, 0, 0, 0);

    return $vbox;
}

# ---------------------------------------------------------------
# TAB 2: REGISTRO
# ---------------------------------------------------------------
sub _tab_registro {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(30);
    $vbox->set_margin_end(30);
    $vbox->set_margin_top(15);
    $vbox->set_margin_bottom(15);

    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span foreground="white" weight="bold" size="large">Registro de Usuario</span>');
    $vbox->pack_start($titulo, 0, 0, 6);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(10);
    $grid->set_row_spacing(6);
    $vbox->pack_start($grid, 0, 0, 0);

    my @campos = (
        ['Núm. Colegio:', 'reg_col'],
        ['Nombre completo:', 'reg_nom'],
        ['Especialidad:', 'reg_esp'],
        ['Contraseña:', 'reg_pass'],
    );
    for my $i (0..$#campos) {
        my $lbl = Gtk3::Label->new($campos[$i][0]);
        $lbl->set_markup("<span foreground='white'>$campos[$i][0]</span>");
        $lbl->set_halign('start');
        $grid->attach($lbl, 0, $i, 1, 1);
        my $entry = Gtk3::Entry->new();
        $entry->set_visibility(0) if $campos[$i][1] eq 'reg_pass';
        $self->{ $campos[$i][1] } = $entry;
        $grid->attach($entry, 1, $i, 1, 1);
    }

    # ComboBox tipo usuario
    my $lbl_tipo = Gtk3::Label->new('');
    $lbl_tipo->set_markup("<span foreground='white'>Tipo usuario:</span>");
    $lbl_tipo->set_halign('start');
    $grid->attach($lbl_tipo, 0, 4, 1, 1);
    $self->{reg_tipo} = Gtk3::ComboBoxText->new();
    for my $t ('TIPO-01 - Médico General', 'TIPO-02 - Especialista/Cirujano',
               'TIPO-03 - Enfermero/a', 'TIPO-04 - Técnico Lab', 'TIPO-05 - Admin Depto') {
        $self->{reg_tipo}->append_text($t);
    }
    $self->{reg_tipo}->set_active(0);
    $grid->attach($self->{reg_tipo}, 1, 4, 1, 1);

    # ComboBox departamento
    my $lbl_dep = Gtk3::Label->new('');
    $lbl_dep->set_markup("<span foreground='white'>Departamento:</span>");
    $lbl_dep->set_halign('start');
    $grid->attach($lbl_dep, 0, 5, 1, 1);
    $self->{reg_dep} = Gtk3::ComboBoxText->new();
    for my $d ('DEP-MED - Medicina General', 'DEP-CIR - Cirugía',
               'DEP-LAB - Laboratorio', 'DEP-FAR - Farmacia') {
        $self->{reg_dep}->append_text($d);
    }
    $self->{reg_dep}->set_active(0);
    $grid->attach($self->{reg_dep}, 1, 5, 1, 1);

    $self->{lbl_reg_msg} = Gtk3::Label->new('');
    $vbox->pack_start($self->{lbl_reg_msg}, 0, 0, 2);

    my $btn = Gtk3::Button->new('Registrarse');
    $btn->get_style_context()->add_class('btn-login');
    $btn->signal_connect(clicked => sub { $self->_hacer_registro() });
    $vbox->pack_start($btn, 0, 0, 4);

    return $vbox;
}

# ---------------------------------------------------------------
# TAB 3: INFORMACIÓN
# ---------------------------------------------------------------
sub _tab_info {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_margin_start(30);
    $vbox->set_margin_end(30);
    $vbox->set_margin_top(30);

    my $info = Gtk3::Label->new('');
    $info->set_markup(
        "<span foreground='white' size='large' weight='bold'>EDD MedTrack - Fase 2</span>\n\n" .
        "<span foreground='#aaaaaa'>Universidad San Carlos de Guatemala\n" .
        "Facultad de Ingeniería\n" .
        "Ingeniería en Ciencias y Sistemas\n\n" .
        "Estructuras de Datos - 1S 2026\n\n" .
        "Desarrollado por:\n" .
        "Estudiante: #202308208\n" .
        "Sección: A</span>"
    );
    $info->set_justify('center');
    $vbox->pack_start($info, 0, 0, 0);

    return $vbox;
}

# ---------------------------------------------------------------
# ACCION: Hacer login
# ---------------------------------------------------------------
sub _hacer_login {
    my ($self) = @_;
    my $user = $self->{entry_user}->get_text();
    my $pass = $self->{entry_pass}->get_text();

    # Login administrador
    if ($user eq ADMIN_USER && $pass eq ADMIN_PASS) {
        Estado->get_instancia()->set_es_admin(1);
        Estado->get_instancia()->set_usuario_actual(undef);
        $self->{ventana}->hide();
        require VentanaAdmin;
        VentanaAdmin->nueva($self->{ventana});
        return;
    }

    # Login usuario departamental (buscar en AVL)
    my $estado = Estado->get_instancia();
    my $usuario = $estado->usuarios->buscar($user);

    if ($usuario && $usuario->get_contrasena() eq $pass) {
        $estado->set_es_admin(0);
        $estado->set_usuario_actual($usuario);
        $self->{ventana}->hide();
        require VentanaUsuario;
        VentanaUsuario->nueva($self->{ventana});
        return;
    }

    # Credenciales incorrectas
    $self->{lbl_error}->set_markup('<span foreground="#e74c3c">⚠ Credenciales incorrectas</span>');
    $self->{entry_pass}->set_text('');
}

# ---------------------------------------------------------------
# ACCION: Hacer registro
# ---------------------------------------------------------------
sub _hacer_registro {
    my ($self) = @_;
    my $col  = $self->{reg_col}->get_text();
    my $nom  = $self->{reg_nom}->get_text();
    my $esp  = $self->{reg_esp}->get_text();
    my $pass = $self->{reg_pass}->get_text();

    unless ($col && $nom && $pass) {
        $self->{lbl_reg_msg}->set_markup('<span foreground="#e74c3c">Campos obligatorios: colegio, nombre, contraseña</span>');
        return;
    }

    # Extraer codigo TIPO y DEP del ComboBox
    my $tipo_texto = $self->{reg_tipo}->get_active_text() // '';
    my ($tipo) = $tipo_texto =~ /^(TIPO-\d+)/;
    my $dep_texto = $self->{reg_dep}->get_active_text() // '';
    my ($dep) = $dep_texto =~ /^(DEP-\w+)/;

    require Usuario;
    my $usuario = Usuario->new({
        numero_colegio  => $col,
        nombre_completo => $nom,
        tipo_usuario    => $tipo // 'TIPO-01',
        departamento    => $dep  // 'DEP-MED',
        especialidad    => $esp,
        contrasena      => $pass,
    });

    my $ok = Estado->get_instancia()->usuarios->insertar($usuario);
    if ($ok) {
        $self->{lbl_reg_msg}->set_markup('<span foreground="#2ecc71">✓ Usuario registrado exitosamente</span>');
        $self->{reg_col}->set_text('');
        $self->{reg_nom}->set_text('');
        $self->{reg_esp}->set_text('');
        $self->{reg_pass}->set_text('');
    } else {
        $self->{lbl_reg_msg}->set_markup('<span foreground="#e74c3c">⚠ Número de colegio ya registrado</span>');
    }
}

1;
