package VentanaLogin;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Gtk3 -init;

use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/model";
use EstadoF3;

use constant ADMIN_USER => 'AdminHospital';
use constant ADMIN_PASS => 'MedTrack2026';  

sub nueva {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->_construir();
    return $self;
}

sub _construir {
    my ($self) = @_;

    $self->{ventana} = Gtk3::Window->new('toplevel');
    $self->{ventana}->set_title('EDD MedTrack F3');
    $self->{ventana}->set_default_size(500, 460);
    $self->{ventana}->set_position('center');
    $self->{ventana}->set_resizable(0);
    $self->{ventana}->signal_connect(destroy => sub { Gtk3->main_quit });

    # CSS
    my $css = Gtk3::CssProvider->new();
    $css->load_from_data('
        window { background-color: #1a2744; }
        .btn-login { background-color: #e67e22; color: white; font-size: 13px; border-radius: 6px; padding: 6px; }
        .btn-login:hover { background-color: #d35400; }
        notebook tab { background-color: #2c3e6b; color: white; padding: 6px 14px; }
        notebook tab:checked { background-color: #e67e22; }
    ');
    Gtk3::StyleContext::add_provider_for_screen(
        Gtk3::Gdk::Screen::get_default(), $css,
        Gtk3::STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    my $vbox = Gtk3::Box->new('vertical', 0);
    $self->{ventana}->add($vbox);

    # Header
    my $header = Gtk3::Label->new('');
    $header->set_markup('<span foreground="white" size="x-large" weight="bold">EDD MEDTRACK</span>');
    $header->set_margin_top(15);
    $header->set_margin_bottom(8);
    $vbox->pack_start($header, 0, 0, 0);

    my $sub = Gtk3::Label->new('');
    $sub->set_markup('<span foreground="#ffffff" size="small"></span>');
    $sub->set_margin_bottom(5);
    $vbox->pack_start($sub, 0, 0, 0);

    my $nb = Gtk3::Notebook->new();
    $nb->set_margin_start(20); $nb->set_margin_end(20); $nb->set_margin_bottom(15);
    $vbox->pack_start($nb, 1, 1, 0);

    $nb->append_page($self->_tab_login(),    Gtk3::Label->new('Iniciar Sesión'));
    $nb->append_page($self->_tab_registro(), Gtk3::Label->new('Registro'));
    $nb->append_page($self->_tab_info(),     Gtk3::Label->new('Información'));

    $self->{ventana}->show_all();
}

# ---------------------------------------------------------------
# TAB LOGIN
# ---------------------------------------------------------------
sub _tab_login {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_margin_start(40); $vbox->set_margin_end(40);
    $vbox->set_margin_top(20);   $vbox->set_margin_bottom(20);

    my $logo = Gtk3::Label->new('');
    $logo->set_markup('<span foreground="#000000" size="large">Hospital General San Carlos</span>');
    $vbox->pack_start($logo, 0, 0, 8);

    my $lbl = Gtk3::Label->new('');
    $lbl->set_markup('<span foreground="#000000" size="large" weight="bold">LOGIN</span>');
    $vbox->pack_start($lbl, 0, 0, 4);

    my $lu = Gtk3::Label->new('');
    $lu->set_markup('<span foreground="#000000">USUARIO</span>');
    $lu->set_halign('start');
    $vbox->pack_start($lu, 0, 0, 0);

    $self->{entry_user} = Gtk3::Entry->new();
    $self->{entry_user}->set_placeholder_text('Núm. colegio o AdminHospital');
    $vbox->pack_start($self->{entry_user}, 0, 0, 2);

    my $lp = Gtk3::Label->new('');
    $lp->set_markup('<span foreground="#000000">CONTRASEÑA</span>');
    $lp->set_halign('start');
    $vbox->pack_start($lp, 0, 0, 0);

    $self->{entry_pass} = Gtk3::Entry->new();
    $self->{entry_pass}->set_visibility(0);
    $self->{entry_pass}->set_placeholder_text('Contraseña');
    $vbox->pack_start($self->{entry_pass}, 0, 0, 4);

    $self->{lbl_error} = Gtk3::Label->new('');
    $vbox->pack_start($self->{lbl_error}, 0, 0, 0);

    my $btn = Gtk3::Button->new('Iniciar Sesión');
    $btn->get_style_context()->add_class('btn-login');
    $btn->signal_connect(clicked => sub { $self->_hacer_login() });
    $self->{entry_pass}->signal_connect(activate => sub { $self->_hacer_login() });
    $vbox->pack_start($btn, 0, 0, 4);

    my $link = Gtk3::Label->new('');
    $link->set_markup('<span foreground="#aaaaaa">¿Sin cuenta? Usa la pestaña Registro</span>');
    $vbox->pack_start($link, 0, 0, 0);

    return $vbox;
}

# ---------------------------------------------------------------
# TAB REGISTRO
# ---------------------------------------------------------------
sub _tab_registro {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(30); $vbox->set_margin_end(30);
    $vbox->set_margin_top(15);   $vbox->set_margin_bottom(15);

    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span foreground="#000000" weight="bold" size="large">Registro de Usuario</span>');
    $vbox->pack_start($titulo, 0, 0, 6);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(10); $grid->set_row_spacing(6);
    $vbox->pack_start($grid, 0, 0, 0);

    my @campos = (
        ['Núm. Colegio:',   'reg_col'],
        ['Nombre completo:', 'reg_nom'],
        ['Especialidad:',    'reg_esp'],
        ['Contraseña:',      'reg_pass'],
    );
    for my $i (0..$#campos) {
        my $lbl = Gtk3::Label->new('');
        $lbl->set_markup("<span foreground='#000000'>$campos[$i][0]</span>");
        $lbl->set_halign('start');
        $grid->attach($lbl, 0, $i, 1, 1);
        my $e = Gtk3::Entry->new();
        $e->set_visibility(0) if $campos[$i][1] eq 'reg_pass';
        $self->{ $campos[$i][1] } = $e;
        $grid->attach($e, 1, $i, 1, 1);
    }

    # Combo tipo
    my $lt = Gtk3::Label->new('');
    $lt->set_markup("<span foreground='#000000'>Tipo usuario:</span>");
    $lt->set_halign('start');
    $grid->attach($lt, 0, 4, 1, 1);
    $self->{reg_tipo} = Gtk3::ComboBoxText->new();
    for my $t ('TIPO-01 - Médico General', 'TIPO-02 - Especialista/Cirujano',
               'TIPO-03 - Enfermero/a',    'TIPO-04 - Técnico Lab') {
        $self->{reg_tipo}->append_text($t);
    }
    $self->{reg_tipo}->set_active(0);
    $grid->attach($self->{reg_tipo}, 1, 4, 1, 1);

    # Combo departamento
    my $ld = Gtk3::Label->new('');
    $ld->set_markup("<span foreground='#000000'>Departamento:</span>");
    $ld->set_halign('start');
    $grid->attach($ld, 0, 5, 1, 1);
    $self->{reg_dep} = Gtk3::ComboBoxText->new();
    for my $d ('DEP-MED - Medicina General', 'DEP-CIR - Cirugía',
               'DEP-LAB - Laboratorio',       'DEP-FAR - Farmacia',
               'SIN-DEP - Sin departamento') {
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
# TAB INFO
# ---------------------------------------------------------------
sub _tab_info {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_margin_start(30); $vbox->set_margin_top(30);

    my $info = Gtk3::Label->new('');
    $info->set_markup(
        "<span foreground='white' size='large' weight='bold'>EDD MedTrack</span>\n\n" .
        "<span foreground='#000000'>Universidad San Carlos de Guatemala\n" .
        "Facultad de Ingeniería\n" .
        "Ingeniería en Ciencias y Sistemas\n\n" .
        "Estructuras de Datos - 1S 2026\n\n" .
        "Estudiante: #202308208 | Sección A</span>"
    );
    $info->set_justify('center');
    $vbox->pack_start($info, 0, 0, 0);
    return $vbox;
}

# ---------------------------------------------------------------
# ACCION: Login
# ---------------------------------------------------------------
sub _hacer_login {
    my ($self) = @_;
    my $user = $self->{entry_user}->get_text();
    my $pass = $self->{entry_pass}->get_text();

    if ($user eq ADMIN_USER && $pass eq ADMIN_PASS) {
        EstadoF3->get_instancia()->set_es_admin(1);
        EstadoF3->get_instancia()->set_usuario_actual(undef);
        $self->{ventana}->hide();
        require VentanaAdmin;
        VentanaAdmin->nueva($self->{ventana});
        return;
    }

    my $estado  = EstadoF3->get_instancia();
    my $usuario = $estado->usuarios->buscar($user);

    if ($usuario && $usuario->get_contrasena() eq $pass) {
        if (($usuario->get_departamento() // 'SIN-DEP') eq 'SIN-DEP') {
            $self->{lbl_error}->set_markup('<span foreground="#e67e22">⚠ Sin departamento asignado. Contacta al administrador.</span>');
            $self->{entry_pass}->set_text('');
            return;
        }
        $estado->set_es_admin(0);
        $estado->set_usuario_actual($usuario);
        # Cargar chats del usuario
        $estado->cargar_chats_usuario($usuario->get_numero_colegio());
        $self->{ventana}->hide();
        require VentanaUsuario;
        VentanaUsuario->nueva($self->{ventana});
        return;
    }

    $self->{lbl_error}->set_markup('<span foreground="#e74c3c">⚠ Credenciales incorrectas</span>');
    $self->{entry_pass}->set_text('');
}

# ---------------------------------------------------------------
# ACCION: Registro
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

    my $tipo_txt = $self->{reg_tipo}->get_active_text() // '';
    my ($tipo)   = $tipo_txt =~ /^(TIPO-\d+)/;
    my $dep_txt  = $self->{reg_dep}->get_active_text() // '';
    my ($dep)    = $dep_txt =~ /^([\w-]+)/;

    require Usuario;
    my $usuario = Usuario->new({
        numero_colegio  => $col,
        nombre_completo => $nom,
        tipo_usuario    => $tipo // 'TIPO-01',
        departamento    => $dep  // 'SIN-DEP',
        especialidad    => $esp,
        contrasena      => $pass,
    });

    my $ok = EstadoF3->get_instancia()->registrar_usuario($usuario);
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

sub show_all { $_[0]->{ventana}->show_all() }

1;
