package VentanaUsuario;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Gtk3 -init;
use Estado;

sub nueva {
    my ($class, $ventana_login) = @_;
    my $self = bless { ventana_login => $ventana_login }, $class;
    $self->_construir();
    return $self;
}

sub _construir {
    my ($self) = @_;
    my $estado  = Estado->get_instancia();
    my $usuario = $estado->get_usuario_actual();

    my $win = Gtk3::Window->new('toplevel');
    $self->{win} = $win;
    $win->set_title('EDD MedTrack - Usuario Departamental');
    $win->set_default_size(850, 600);
    $win->set_position('center');
    $win->signal_connect(destroy => sub {
        $estado->set_usuario_actual(undef);
        $self->{ventana_login}->show_all() if defined $self->{ventana_login};
    });

    my $vbox = Gtk3::Box->new('vertical', 0);
    $win->add($vbox);

    # Header
    my $header = $self->_crear_header($usuario);
    $vbox->pack_start($header, 0, 0, 0);

    # Notebook — tabs segun permisos del usuario
    my $nb = Gtk3::Notebook->new();
    $vbox->pack_start($nb, 1, 1, 0);

    my @permisos = @{ $usuario->get_permisos() };

    # Tab medicamentos si tiene permiso
    if (grep { $_ eq 'MEDICAMENTO' } @permisos) {
        $nb->append_page($self->_tab_medicamentos(), Gtk3::Label->new('💊 Medicamentos'));
    }
    # Tab equipos si tiene permiso
    if (grep { $_ eq 'EQUIPO' } @permisos) {
        $nb->append_page($self->_tab_equipos(), Gtk3::Label->new('🔧 Equipos'));
    }
    # Tab suministros si tiene permiso
    if (grep { $_ eq 'SUMINISTRO' } @permisos) {
        $nb->append_page($self->_tab_suministros(), Gtk3::Label->new('📦 Suministros'));
    }

    # Tab perfil siempre visible
    $nb->append_page($self->_tab_perfil(), Gtk3::Label->new('👤 Mi Perfil'));

    $win->show_all();
}

# ---------------------------------------------------------------
# HEADER con bienvenida
# ---------------------------------------------------------------
sub _crear_header {
    my ($self, $usuario) = @_;
    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->override_background_color('normal', Gtk3::Gdk::RGBA::parse('#1a2744'));

    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span foreground="white" size="large" weight="bold"> EDD MEDTRACK </span>');
    $titulo->set_margin_start(15);
    $titulo->set_margin_top(10);
    $titulo->set_margin_bottom(10);
    $hbox->pack_start($titulo, 0, 0, 0);

    my $nom  = $usuario->get_nombre_completo();
    my $tipo = $usuario->get_tipo_usuario();
    my $dep  = $usuario->get_departamento();
    my $bienvenido = Gtk3::Label->new('');
    $bienvenido->set_markup(
        "<span foreground='#e67e22' size='small'> Bienvenido, $tipo | $dep | $nom </span>"
    );
    $hbox->pack_end($bienvenido, 0, 0, 15);

    return $hbox;
}

# ---------------------------------------------------------------
# HELPER: ScrolledWindow
# ---------------------------------------------------------------
sub _en_scrolled {
    my ($self, $widget) = @_;
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->add($widget);
    return $sw;
}

# ---------------------------------------------------------------
# HELPER: crear TreeView
# ---------------------------------------------------------------
sub _crear_treeview {
    my ($self, @cols) = @_;
    my $store = Gtk3::ListStore->new(map { 'Glib::String' } @cols);
    my $tv    = Gtk3::TreeView->new($store);
    $tv->set_rules_hint(1);
    for my $i (0..$#cols) {
        my $r   = Gtk3::CellRendererText->new();
        my $col = Gtk3::TreeViewColumn->new_with_attributes($cols[$i], $r, text => $i);
        $col->set_resizable(1);
        $tv->append_column($col);
    }
    return ($tv, $store);
}

# ---------------------------------------------------------------
# TAB: CONSULTAR MEDICAMENTOS
# ---------------------------------------------------------------
sub _tab_medicamentos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10);
    $vbox->set_margin_top(10); $vbox->set_margin_bottom(10);

    # Barra de búsqueda
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $lbl = Gtk3::Label->new('Buscar:');
    $self->{med_entry} = Gtk3::Entry->new();
    $self->{med_entry}->set_placeholder_text('Código o nombre...');
    $self->{med_entry}->set_size_request(200, -1);

    my $btn_cod = Gtk3::Button->new('🔍 Por código');
    my $btn_nom = Gtk3::Button->new('🔍 Por nombre');
    my $btn_ver = Gtk3::Button->new('📋 Ver todos');

    $hbox->pack_start($lbl,      0, 0, 0);
    $hbox->pack_start($self->{med_entry}, 0, 0, 0);
    $hbox->pack_start($btn_cod,  0, 0, 0);
    $hbox->pack_start($btn_nom,  0, 0, 0);
    $hbox->pack_end($btn_ver,    0, 0, 0);

    # Resultado / tabla
    my ($tv, $store) = $self->_crear_treeview(
        'Código', 'Nombre', 'Disponible', 'Vencimiento', 'Estado'
    );
    $self->{med_res_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    # Alerta de stock
    $self->{med_alerta} = Gtk3::Label->new('');
    $vbox->pack_start($self->{med_alerta}, 0, 0, 0);

    # Señales
    $btn_cod->signal_connect(clicked => sub {
        my $cod = $self->{med_entry}->get_text();
        my $m = Estado->get_instancia()->medicamentos->buscar($cod);
        $self->_mostrar_medicamento($m);
    });
    $btn_nom->signal_connect(clicked => sub {
        my $nom = $self->{med_entry}->get_text();
        my $m = Estado->get_instancia()->medicamentos->buscar_por_nombre($nom);
        $self->_mostrar_medicamento($m);
    });
    $btn_ver->signal_connect(clicked => sub {
        $self->_listar_todos_medicamentos();
    });
    $self->{med_entry}->signal_connect(activate => sub {
        my $cod = $self->{med_entry}->get_text();
        my $m = Estado->get_instancia()->medicamentos->buscar($cod);
        $self->_mostrar_medicamento($m);
    });

    return $vbox;
}

sub _mostrar_medicamento {
    my ($self, $m) = @_;
    $self->{med_res_store}->clear();
    $self->{med_alerta}->set_text('');

    unless ($m) {
        $self->{med_alerta}->set_markup('<span foreground="#e74c3c">⚠ Medicamento no encontrado.</span>');
        return;
    }

    my $estado_txt = $m->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Normal';
    my $iter = $self->{med_res_store}->append();
    $self->{med_res_store}->set($iter,
        0, $m->get_codigo(),
        1, $m->get_nombre(),
        2, $m->get_cantidad(),
        3, $m->get_fechaVencimiento(),
        4, $estado_txt,
    );

    if ($m->bajo_stock()) {
        $self->{med_alerta}->set_markup(
            '<span foreground="#e67e22">⏳ Stock bajo el nivel mínimo — en proceso de reabastecimiento</span>'
        );
    }
}

sub _listar_todos_medicamentos {
    my ($self) = @_;
    $self->{med_res_store}->clear();
    $self->{med_alerta}->set_text('');

    my $lista  = Estado->get_instancia()->medicamentos;
    my $actual = $lista->{primero};
    my $alertas = 0;

    while ($actual) {
        my $m = $actual->get_dato();
        my $estado_txt = $m->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Normal';
        my $iter = $self->{med_res_store}->append();
        $self->{med_res_store}->set($iter,
            0, $m->get_codigo(),
            1, $m->get_nombre(),
            2, $m->get_cantidad(),
            3, $m->get_fechaVencimiento(),
            4, $estado_txt,
        );
        $alertas++ if $m->bajo_stock();
        $actual = $actual->get_siguiente();
    }

    if ($alertas > 0) {
        $self->{med_alerta}->set_markup(
            "<span foreground='#e74c3c'>⚠ $alertas medicamento(s) con stock bajo el nivel mínimo</span>"
        );
    }
}

# ---------------------------------------------------------------
# TAB: CONSULTAR EQUIPOS (BST)
# ---------------------------------------------------------------
sub _tab_equipos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10);
    $vbox->set_margin_top(10); $vbox->set_margin_bottom(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $lbl = Gtk3::Label->new('Código equipo:');
    $self->{eq_entry} = Gtk3::Entry->new();
    $self->{eq_entry}->set_placeholder_text('EQU...');
    $self->{eq_entry}->set_size_request(180, -1);

    my $btn_bus = Gtk3::Button->new('🔍 Buscar');
    my $btn_ver = Gtk3::Button->new('📋 Ver todos');

    $hbox->pack_start($lbl,             0, 0, 0);
    $hbox->pack_start($self->{eq_entry}, 0, 0, 0);
    $hbox->pack_start($btn_bus,          0, 0, 0);
    $hbox->pack_end($btn_ver,            0, 0, 0);

    my ($tv, $store) = $self->_crear_treeview(
        'Código', 'Nombre', 'Fabricante', 'Precio', 'Disponible', 'Fecha Ingreso', 'Estado'
    );
    $self->{eq_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    $self->{eq_alerta} = Gtk3::Label->new('');
    $vbox->pack_start($self->{eq_alerta}, 0, 0, 0);

    $btn_bus->signal_connect(clicked => sub {
        my $cod = $self->{eq_entry}->get_text();
        my $e = Estado->get_instancia()->equipos->buscar($cod);
        $self->_mostrar_equipo($e);
    });
    $btn_ver->signal_connect(clicked => sub {
        $self->_listar_todos_equipos();
    });
    $self->{eq_entry}->signal_connect(activate => sub {
        my $cod = $self->{eq_entry}->get_text();
        my $e = Estado->get_instancia()->equipos->buscar($cod);
        $self->_mostrar_equipo($e);
    });

    return $vbox;
}

sub _mostrar_equipo {
    my ($self, $e) = @_;
    $self->{eq_store}->clear();
    $self->{eq_alerta}->set_text('');

    unless ($e) {
        $self->{eq_alerta}->set_markup('<span foreground="#e74c3c">⚠ Equipo no encontrado.</span>');
        return;
    }

    my $estado_txt = $e->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible';
    my $iter = $self->{eq_store}->append();
    $self->{eq_store}->set($iter,
        0, $e->get_codigo(),
        1, $e->get_nombre(),
        2, $e->get_fabricante(),
        3, sprintf("Q%.2f", $e->get_precio()),
        4, $e->get_cantidad(),
        5, $e->get_fecha_ingreso(),
        6, $estado_txt,
    );

    if ($e->bajo_stock()) {
        $self->{eq_alerta}->set_markup(
            '<span foreground="#e74c3c">⚠ Equipo con stock bajo el nivel mínimo</span>'
        );
    }
}

sub _listar_todos_equipos {
    my ($self) = @_;
    $self->{eq_store}->clear();
    $self->{eq_alerta}->set_text('');
    my $alertas = 0;

    for my $e (Estado->get_instancia()->equipos->inorden()) {
        my $estado_txt = $e->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible';
        my $iter = $self->{eq_store}->append();
        $self->{eq_store}->set($iter,
            0, $e->get_codigo(),
            1, $e->get_nombre(),
            2, $e->get_fabricante(),
            3, sprintf("Q%.2f", $e->get_precio()),
            4, $e->get_cantidad(),
            5, $e->get_fecha_ingreso(),
            6, $estado_txt,
        );
        $alertas++ if $e->bajo_stock();
    }

    if ($alertas > 0) {
        $self->{eq_alerta}->set_markup(
            "<span foreground='#e74c3c'>⚠ $alertas equipo(s) con stock bajo</span>"
        );
    }
}

# ---------------------------------------------------------------
# TAB: CONSULTAR SUMINISTROS (Árbol B)
# ---------------------------------------------------------------
sub _tab_suministros {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10);
    $vbox->set_margin_top(10); $vbox->set_margin_bottom(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $lbl = Gtk3::Label->new('Código suministro:');
    $self->{sum_entry} = Gtk3::Entry->new();
    $self->{sum_entry}->set_placeholder_text('SUM...');
    $self->{sum_entry}->set_size_request(180, -1);

    my $btn_bus = Gtk3::Button->new('🔍 Buscar');
    my $btn_ver = Gtk3::Button->new('📋 Ver todos');

    $hbox->pack_start($lbl,              0, 0, 0);
    $hbox->pack_start($self->{sum_entry}, 0, 0, 0);
    $hbox->pack_start($btn_bus,           0, 0, 0);
    $hbox->pack_end($btn_ver,             0, 0, 0);

    my ($tv, $store) = $self->_crear_treeview(
        'Código', 'Nombre', 'Fabricante', 'Precio', 'Disponible', 'Vencimiento', 'Estado'
    );
    $self->{sum_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    $self->{sum_alerta} = Gtk3::Label->new('');
    $vbox->pack_start($self->{sum_alerta}, 0, 0, 0);

    $btn_bus->signal_connect(clicked => sub {
        my $cod = $self->{sum_entry}->get_text();
        my $s = Estado->get_instancia()->suministros->buscar($cod);
        $self->_mostrar_suministro($s);
    });
    $btn_ver->signal_connect(clicked => sub {
        $self->_listar_todos_suministros();
    });
    $self->{sum_entry}->signal_connect(activate => sub {
        my $cod = $self->{sum_entry}->get_text();
        my $s = Estado->get_instancia()->suministros->buscar($cod);
        $self->_mostrar_suministro($s);
    });

    return $vbox;
}

sub _mostrar_suministro {
    my ($self, $s) = @_;
    $self->{sum_store}->clear();
    $self->{sum_alerta}->set_text('');

    unless ($s) {
        $self->{sum_alerta}->set_markup('<span foreground="#e74c3c">⚠ Suministro no encontrado.</span>');
        return;
    }

    my $estado_txt = $s->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible';
    my $iter = $self->{sum_store}->append();
    $self->{sum_store}->set($iter,
        0, $s->get_codigo(),
        1, $s->get_nombre(),
        2, $s->get_fabricante(),
        3, sprintf("Q%.2f", $s->get_precio()),
        4, $s->get_cantidad(),
        5, $s->get_fecha_vencimiento(),
        6, $estado_txt,
    );

    if ($s->bajo_stock()) {
        $self->{sum_alerta}->set_markup(
            '<span foreground="#e74c3c">⚠ Suministro con stock bajo el nivel mínimo</span>'
        );
    }
}

sub _listar_todos_suministros {
    my ($self) = @_;
    $self->{sum_store}->clear();
    $self->{sum_alerta}->set_text('');
    my $alertas = 0;

    for my $s (Estado->get_instancia()->suministros->inorden()) {
        my $estado_txt = $s->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible';
        my $iter = $self->{sum_store}->append();
        $self->{sum_store}->set($iter,
            0, $s->get_codigo(),
            1, $s->get_nombre(),
            2, $s->get_fabricante(),
            3, sprintf("Q%.2f", $s->get_precio()),
            4, $s->get_cantidad(),
            5, $s->get_fecha_vencimiento(),
            6, $estado_txt,
        );
        $alertas++ if $s->bajo_stock();
    }

    if ($alertas > 0) {
        $self->{sum_alerta}->set_markup(
            "<span foreground='#e74c3c'>⚠ $alertas suministro(s) con stock bajo</span>"
        );
    }
}

# ---------------------------------------------------------------
# TAB: PERFIL DE USUARIO
# ---------------------------------------------------------------
sub _tab_perfil {
    my ($self) = @_;
    my $estado  = Estado->get_instancia();
    my $usuario = $estado->get_usuario_actual();

    my $vbox = Gtk3::Box->new('vertical', 12);
    $vbox->set_margin_start(30); $vbox->set_margin_end(30);
    $vbox->set_margin_top(20); $vbox->set_margin_bottom(20);

    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span size="large" weight="bold">Mi Perfil</span>');
    $titulo->set_halign('start');
    $vbox->pack_start($titulo, 0, 0, 0);

    # Información no editable
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(16);
    $grid->set_row_spacing(8);
    $vbox->pack_start($grid, 0, 0, 0);

    my @info = (
        ['Número de colegio:', $usuario->get_numero_colegio()],
        ['Tipo de usuario:',   $usuario->get_tipo_usuario()],
        ['Departamento:',      $usuario->get_departamento()],
        ['Especialidad:',      $usuario->get_especialidad() || 'N/A'],
        ['Acceso a:',          join(', ', @{ $usuario->get_permisos() })],
    );

    for my $i (0..$#info) {
        my $lbl_key = Gtk3::Label->new('');
        $lbl_key->set_markup("<b>$info[$i][0]</b>");
        $lbl_key->set_halign('start');
        $grid->attach($lbl_key, 0, $i, 1, 1);

        my $lbl_val = Gtk3::Label->new($info[$i][1]);
        $lbl_val->set_halign('start');
        $grid->attach($lbl_val, 1, $i, 1, 1);
    }

    # Separador
    $vbox->pack_start(Gtk3::Separator->new('horizontal'), 0, 0, 4);

    # Campos editables
    my $lbl_edit = Gtk3::Label->new('');
    $lbl_edit->set_markup('<b>Editar información:</b>');
    $lbl_edit->set_halign('start');
    $vbox->pack_start($lbl_edit, 0, 0, 0);

    my $grid2 = Gtk3::Grid->new();
    $grid2->set_column_spacing(12);
    $grid2->set_row_spacing(8);
    $vbox->pack_start($grid2, 0, 0, 0);

    # Campo nombre
    $grid2->attach(Gtk3::Label->new('Nombre completo:'), 0, 0, 1, 1);
    $self->{perfil_nom} = Gtk3::Entry->new();
    $self->{perfil_nom}->set_text($usuario->get_nombre_completo());
    $self->{perfil_nom}->set_size_request(280, -1);
    $grid2->attach($self->{perfil_nom}, 1, 0, 1, 1);

    # Campo contraseña
    $grid2->attach(Gtk3::Label->new('Nueva contraseña:'), 0, 1, 1, 1);
    $self->{perfil_pass} = Gtk3::Entry->new();
    $self->{perfil_pass}->set_visibility(0);
    $self->{perfil_pass}->set_placeholder_text('Dejar vacío para no cambiar');
    $self->{perfil_pass}->set_size_request(280, -1);
    $grid2->attach($self->{perfil_pass}, 1, 1, 1, 1);

    # Mensaje de resultado
    $self->{perfil_msg} = Gtk3::Label->new('');
    $vbox->pack_start($self->{perfil_msg}, 0, 0, 0);

    # Botón guardar
    my $btn = Gtk3::Button->new('💾 Guardar cambios');
    $btn->set_halign('start');
    $btn->signal_connect(clicked => sub { $self->_guardar_perfil() });
    $vbox->pack_start($btn, 0, 0, 0);

    return $vbox;
}

sub _guardar_perfil {
    my ($self) = @_;
    my $usuario = Estado->get_instancia()->get_usuario_actual();
    my $nom  = $self->{perfil_nom}->get_text();
    my $pass = $self->{perfil_pass}->get_text();

    if ($nom) {
        $usuario->set_nombre_completo($nom);
    }
    if ($pass) {
        $usuario->set_contrasena($pass);
        $self->{perfil_pass}->set_text('');
    }

    $self->{perfil_msg}->set_markup('<span foreground="#2ecc71">✓ Perfil actualizado correctamente</span>');
}

1;
