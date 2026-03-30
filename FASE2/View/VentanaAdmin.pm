package VentanaAdmin;
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
    my $win = Gtk3::Window->new('toplevel');
    $self->{win} = $win;
    $win->set_title('EDD MedTrack - Administrador');
    $win->set_default_size(1000, 700);
    $win->set_position('center');
    $win->signal_connect(destroy => sub {
        if (defined $self->{ventana_login}) {
            $self->{ventana_login}->show_all();
        } else {
            Gtk3->main_quit;
        }
    });

    my $vbox = Gtk3::Box->new('vertical', 0);
    $win->add($vbox);

    # Header
    my $header = $self->_crear_header("Bienvenido Administrador");
    $vbox->pack_start($header, 0, 0, 0);

    # Notebook principal
    my $nb = Gtk3::Notebook->new();
    $vbox->pack_start($nb, 1, 1, 0);

    $nb->append_page($self->_tab_personal_medico(), Gtk3::Label->new('Personal Médico (AVL)'));
    $nb->append_page($self->_tab_equipos(),         Gtk3::Label->new('Equipos (BST)'));
    $nb->append_page($self->_tab_suministros(),     Gtk3::Label->new('Suministros (Árbol B)'));
    $nb->append_page($self->_tab_medicamentos(),    Gtk3::Label->new('Medicamentos'));
    $nb->append_page($self->_tab_proveedores(),     Gtk3::Label->new('Proveedores'));
    $nb->append_page($self->_tab_carga_masiva(),    Gtk3::Label->new('Carga Masiva'));
    $nb->append_page($self->_tab_reportes(),        Gtk3::Label->new('Reportes'));

    $win->show_all();
}

sub _crear_header {
    my ($self, $texto) = @_;
    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->override_background_color('normal', Gtk3::Gdk::RGBA::parse('#1a2744'));

    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span foreground="white" size="large" weight="bold"> EDD MEDTRACK </span>');
    $titulo->set_margin_start(15);
    $titulo->set_margin_top(10);
    $titulo->set_margin_bottom(10);
    $hbox->pack_start($titulo, 0, 0, 0);

    my $bienvenido = Gtk3::Label->new('');
    $bienvenido->set_markup("<span foreground='#e67e22' size='medium'> $texto </span>");
    $hbox->pack_end($bienvenido, 0, 0, 15);

    return $hbox;
}

# ---------------------------------------------------------------
# Helper: crear TreeView con columnas
# ---------------------------------------------------------------
sub _crear_treeview {
    my ($self, @columnas) = @_;
    my @tipos = map { 'Glib::String' } @columnas;
    my $store = Gtk3::ListStore->new(@tipos);
    my $tv    = Gtk3::TreeView->new($store);
    $tv->set_rules_hint(1);

    for my $i (0..$#columnas) {
        my $r   = Gtk3::CellRendererText->new();
        my $col = Gtk3::TreeViewColumn->new_with_attributes($columnas[$i], $r, text => $i);
        $col->set_sort_column_id($i);
        $col->set_resizable(1);
        $tv->append_column($col);
    }
    return ($tv, $store);
}

sub _en_scrolled {
    my ($self, $widget) = @_;
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->add($widget);
    return $sw;
}

# ---------------------------------------------------------------
# TAB: PERSONAL MÉDICO (AVL)
# ---------------------------------------------------------------
sub _tab_personal_medico {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10);
    $vbox->set_margin_top(10); $vbox->set_margin_bottom(10);

    # Barra de herramientas
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $btn_refrescar = Gtk3::Button->new('↻ Refrescar');
    my $btn_agregar   = Gtk3::Button->new('+ Agregar Usuario');
    my $btn_buscar    = Gtk3::Button->new('🔍 Buscar');
    my $btn_eliminar  = Gtk3::Button->new('✕ Eliminar');
    my $btn_recorrido = Gtk3::Button->new('↕ Recorridos');
    my $entry_buscar  = Gtk3::Entry->new();
    $entry_buscar->set_placeholder_text('Núm. colegio...');

    $hbox->pack_start($btn_agregar,  0, 0, 0);
    $hbox->pack_start($entry_buscar, 0, 0, 0);
    $hbox->pack_start($btn_buscar,   0, 0, 0);
    $hbox->pack_start($btn_eliminar, 0, 0, 0);
    $hbox->pack_start($btn_recorrido,0, 0, 0);
    $hbox->pack_end($btn_refrescar,  0, 0, 0);

    # Tabla
    my ($tv, $store) = $self->_crear_treeview(
        'Núm. Colegio', 'Nombre Completo', 'Tipo', 'Departamento', 'Especialidad'
    );
    $self->{avl_store} = $store;
    $self->{avl_tv}    = $tv;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    # Area de recorridos
    my $lbl_rec = Gtk3::Label->new('Recorridos AVL:');
    $vbox->pack_start($lbl_rec, 0, 0, 0);
    my $tv_rec = Gtk3::TextView->new();
    $tv_rec->set_editable(0);
    $tv_rec->set_size_request(-1, 80);
    $self->{avl_rec_buffer} = $tv_rec->get_buffer();
    $vbox->pack_start($self->_en_scrolled($tv_rec), 0, 0, 0);

    # Señales
    $btn_refrescar->signal_connect(clicked => sub { $self->_refrescar_avl() });
    $btn_agregar->signal_connect(clicked   => sub { $self->_dialog_agregar_usuario() });
    $btn_eliminar->signal_connect(clicked  => sub {
        my $col_txt = $entry_buscar->get_text();
        if ($col_txt) {
            my $ok = Estado->get_instancia()->usuarios->eliminar($col_txt);
            $self->_msg($ok ? "Usuario $col_txt eliminado." : "No encontrado: $col_txt");
            $self->_refrescar_avl() if $ok;
        }
    });
    $btn_buscar->signal_connect(clicked => sub {
        my $col_txt = $entry_buscar->get_text();
        my $u = Estado->get_instancia()->usuarios->buscar($col_txt);
        $self->_msg($u ? $u->to_string() : "No encontrado: $col_txt");
    });
    $btn_recorrido->signal_connect(clicked => sub {
        $self->_mostrar_recorridos_avl();
    });

    $self->_refrescar_avl();
    return $vbox;
}

sub _refrescar_avl {
    my ($self) = @_;
    my $store = $self->{avl_store};
    $store->clear();
    for my $u (Estado->get_instancia()->usuarios->inorden()) {
        my $iter = $store->append();
        $store->set($iter,
            0, $u->get_numero_colegio(),
            1, $u->get_nombre_completo(),
            2, $u->get_tipo_usuario(),
            3, $u->get_departamento(),
            4, $u->get_especialidad() || 'N/A',
        );
    }
}

sub _mostrar_recorridos_avl {
    my ($self) = @_;
    my $avl = Estado->get_instancia()->usuarios;
    my $texto = "=== INORDEN ===\n";
    $texto .= join(", ", map { $_->get_numero_colegio() } $avl->inorden()) || "(vacío)";
    $texto .= "\n\n=== PREORDEN ===\n";
    $texto .= join(", ", map { $_->get_numero_colegio() } $avl->preorden()) || "(vacío)";
    $texto .= "\n\n=== POSTORDEN ===\n";
    $texto .= join(", ", map { $_->get_numero_colegio() } $avl->postorden()) || "(vacío)";
    $self->{avl_rec_buffer}->set_text($texto);
}

sub _dialog_agregar_usuario {
    my ($self) = @_;
    my $dialog = Gtk3::Dialog->new('Agregar Usuario', $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $dialog->set_default_size(380, 320);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);

    my %entries;
    my @filas = (
        ['Núm. Colegio:', 'col'],
        ['Nombre completo:', 'nom'],
        ['Especialidad:', 'esp'],
        ['Contraseña:', 'pass'],
    );
    for my $i (0..$#filas) {
        $grid->attach(Gtk3::Label->new($filas[$i][0]), 0, $i, 1, 1);
        my $e = Gtk3::Entry->new();
        $e->set_visibility(0) if $filas[$i][1] eq 'pass';
        $entries{ $filas[$i][1] } = $e;
        $grid->attach($e, 1, $i, 1, 1);
    }

    my $combo_tipo = Gtk3::ComboBoxText->new();
    my $combo_dep  = Gtk3::ComboBoxText->new();
    for my $t ('TIPO-01', 'TIPO-02', 'TIPO-03', 'TIPO-04', 'TIPO-05') { $combo_tipo->append_text($t) }
    for my $d ('DEP-MED', 'DEP-CIR', 'DEP-LAB', 'DEP-FAR') { $combo_dep->append_text($d) }
    $combo_tipo->set_active(0); $combo_dep->set_active(0);
    $grid->attach(Gtk3::Label->new('Tipo:'), 0, 4, 1, 1);
    $grid->attach($combo_tipo, 1, 4, 1, 1);
    $grid->attach(Gtk3::Label->new('Departamento:'), 0, 5, 1, 1);
    $grid->attach($combo_dep,  1, 5, 1, 1);

    $dialog->get_content_area()->add($grid);
    $dialog->show_all();

    if ($dialog->run() eq 'ok') {
        require Usuario;
        my $u = Usuario->new({
            numero_colegio  => $entries{col}->get_text(),
            nombre_completo => $entries{nom}->get_text(),
            tipo_usuario    => $combo_tipo->get_active_text(),
            departamento    => $combo_dep->get_active_text(),
            especialidad    => $entries{esp}->get_text(),
            contrasena      => $entries{pass}->get_text(),
        });
        my $ok = Estado->get_instancia()->usuarios->insertar($u);
        $self->_msg($ok ? "Usuario agregado." : "Error: colegio ya existe.");
        $self->_refrescar_avl() if $ok;
    }
    $dialog->destroy();
}

# ---------------------------------------------------------------
# TAB: EQUIPOS (BST)
# ---------------------------------------------------------------
sub _tab_equipos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10);
    $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text('Código equipo...');
    my $btn_add = Gtk3::Button->new('+ Agregar');
    my $btn_bus = Gtk3::Button->new(' Buscar');
    my $btn_del = Gtk3::Button->new('✕ Eliminar');
    my $btn_rec = Gtk3::Button->new('↕ Recorridos');
    my $btn_ref = Gtk3::Button->new('↻');
    $hbox->pack_start($btn_add, 0,0,0); $hbox->pack_start($entry, 0,0,0);
    $hbox->pack_start($btn_bus, 0,0,0); $hbox->pack_start($btn_del, 0,0,0);
    $hbox->pack_start($btn_rec, 0,0,0); $hbox->pack_end($btn_ref, 0,0,0);

    my ($tv, $store) = $self->_crear_treeview(
        'Código', 'Nombre', 'Fabricante', 'Precio', 'Cantidad', 'Fecha Ingreso', 'Nivel Mín'
    );
    $self->{bst_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    my $tv_rec = Gtk3::TextView->new(); $tv_rec->set_editable(0); $tv_rec->set_size_request(-1, 70);
    $self->{bst_rec_buf} = $tv_rec->get_buffer();
    $vbox->pack_start($self->_en_scrolled($tv_rec), 0, 0, 0);

    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_bst() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_agregar_equipo() });
    $btn_del->signal_connect(clicked => sub {
        my $cod = $entry->get_text();
        return unless $cod;
        my $ok = Estado->get_instancia()->equipos->eliminar($cod);
        $self->_msg($ok ? "Equipo $cod eliminado." : "No encontrado: $cod");
        $self->_refrescar_bst() if $ok;
    });
    $btn_bus->signal_connect(clicked => sub {
        my $cod = $entry->get_text();
        my $e = Estado->get_instancia()->equipos->buscar($cod);
        $self->_msg($e ? $e->to_string() : "No encontrado: $cod");
    });
    $btn_rec->signal_connect(clicked => sub {
        my $bst = Estado->get_instancia()->equipos;
        my $t = "INORDEN: " . join(", ", map { $_->get_codigo() } $bst->inorden()) . "\n";
        $t   .= "PREORDEN: " . join(", ", map { $_->get_codigo() } $bst->preorden()) . "\n";
        $t   .= "POSTORDEN: " . join(", ", map { $_->get_codigo() } $bst->postorden());
        $self->{bst_rec_buf}->set_text($t);
    });

    $self->_refrescar_bst();
    return $vbox;
}

sub _refrescar_bst {
    my ($self) = @_;
    $self->{bst_store}->clear();
    for my $e (Estado->get_instancia()->equipos->inorden()) {
        my $iter = $self->{bst_store}->append();
        $self->{bst_store}->set($iter,
            0, $e->get_codigo(), 1, $e->get_nombre(), 2, $e->get_fabricante(),
            3, sprintf("Q%.2f", $e->get_precio()), 4, $e->get_cantidad(),
            5, $e->get_fecha_ingreso(), 6, $e->get_nivel_minimo(),
        );
    }
}

sub _dialog_agregar_equipo {
    my ($self) = @_;
    my $dialog = Gtk3::Dialog->new('Agregar Equipo', $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $dialog->set_default_size(350, 300);
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);

    my @campos = (['Código (EQU...):', 'cod'], ['Nombre:', 'nom'], ['Fabricante:', 'fab'],
                  ['Precio Q:', 'pre'], ['Cantidad:', 'cant'],
                  ['Fecha ingreso (YYYY-MM-DD):', 'fec'], ['Nivel mínimo:', 'niv']);
    my %e;
    for my $i (0..$#campos) {
        $grid->attach(Gtk3::Label->new($campos[$i][0]), 0, $i, 1, 1);
        $e{ $campos[$i][1] } = Gtk3::Entry->new();
        $grid->attach($e{ $campos[$i][1] }, 1, $i, 1, 1);
    }
    $dialog->get_content_area()->add($grid);
    $dialog->show_all();

    if ($dialog->run() eq 'ok') {
        require Equipo;
        my $eq = Equipo->new({
            codigo => $e{cod}->get_text(), nombre => $e{nom}->get_text(),
            fabricante => $e{fab}->get_text(), precio => $e{pre}->get_text() || 0,
            cantidad => $e{cant}->get_text() || 0, fecha_ingreso => $e{fec}->get_text(),
            nivel_minimo => $e{niv}->get_text() || 0,
        });
        Estado->get_instancia()->equipos->insertar($eq);
        $self->_refrescar_bst();
    }
    $dialog->destroy();
}

# ---------------------------------------------------------------
# TAB: SUMINISTROS (Árbol B)
# ---------------------------------------------------------------
sub _tab_suministros {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text('Código suministro...');
    my $btn_add = Gtk3::Button->new('+ Agregar');
    my $btn_bus = Gtk3::Button->new(' Buscar');
    my $btn_del = Gtk3::Button->new('✕ Eliminar');
    my $btn_ref = Gtk3::Button->new('↻');
    $hbox->pack_start($btn_add,0,0,0); $hbox->pack_start($entry,0,0,0);
    $hbox->pack_start($btn_bus,0,0,0); $hbox->pack_start($btn_del,0,0,0);
    $hbox->pack_end($btn_ref,0,0,0);

    my ($tv, $store) = $self->_crear_treeview(
        'Código', 'Nombre', 'Fabricante', 'Precio', 'Cantidad', 'Vencimiento', 'Nivel Mín'
    );
    $self->{b_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_arbolb() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_agregar_suministro() });
    $btn_del->signal_connect(clicked => sub {
        my $cod = $entry->get_text(); return unless $cod;
        my $ok = Estado->get_instancia()->suministros->eliminar($cod);
        $self->_msg($ok ? "Suministro $cod eliminado." : "No encontrado: $cod");
        $self->_refrescar_arbolb() if $ok;
    });
    $btn_bus->signal_connect(clicked => sub {
        my $cod = $entry->get_text();
        my $s = Estado->get_instancia()->suministros->buscar($cod);
        $self->_msg($s ? $s->to_string() : "No encontrado: $cod");
    });

    $self->_refrescar_arbolb();
    return $vbox;
}

sub _refrescar_arbolb {
    my ($self) = @_;
    $self->{b_store}->clear();
    for my $s (Estado->get_instancia()->suministros->inorden()) {
        my $iter = $self->{b_store}->append();
        $self->{b_store}->set($iter,
            0, $s->get_codigo(), 1, $s->get_nombre(), 2, $s->get_fabricante(),
            3, sprintf("Q%.2f", $s->get_precio()), 4, $s->get_cantidad(),
            5, $s->get_fecha_vencimiento(), 6, $s->get_nivel_minimo(),
        );
    }
}

sub _dialog_agregar_suministro {
    my ($self) = @_;
    my $dialog = Gtk3::Dialog->new('Agregar Suministro', $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $dialog->set_default_size(350, 290);
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);

    my @campos = (['Código (SUM...):', 'cod'], ['Nombre:', 'nom'], ['Fabricante:', 'fab'],
                  ['Precio Q:', 'pre'], ['Cantidad:', 'cant'],
                  ['Vencimiento (YYYY-MM-DD):', 'fec'], ['Nivel mínimo:', 'niv']);
    my %e;
    for my $i (0..$#campos) {
        $grid->attach(Gtk3::Label->new($campos[$i][0]), 0, $i, 1, 1);
        $e{ $campos[$i][1] } = Gtk3::Entry->new();
        $grid->attach($e{ $campos[$i][1] }, 1, $i, 1, 1);
    }
    $dialog->get_content_area()->add($grid);
    $dialog->show_all();

    if ($dialog->run() eq 'ok') {
        require Suministro;
        my $sum = Suministro->new({
            codigo => $e{cod}->get_text(), nombre => $e{nom}->get_text(),
            fabricante => $e{fab}->get_text(), precio => $e{pre}->get_text() || 0,
            cantidad => $e{cant}->get_text() || 0, fecha_vencimiento => $e{fec}->get_text(),
            nivel_minimo => $e{niv}->get_text() || 0,
        });
        Estado->get_instancia()->suministros->insertar($sum);
        $self->_refrescar_arbolb();
    }
    $dialog->destroy();
}

# ---------------------------------------------------------------
# TAB: MEDICAMENTOS
# ---------------------------------------------------------------
sub _tab_medicamentos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    my $btn_ref = Gtk3::Button->new('↻ Refrescar');
    my $btn_add = Gtk3::Button->new('+ Agregar');
    $hbox->pack_start($btn_add, 0,0,0);
    $hbox->pack_end($btn_ref, 0,0,0);
    $vbox->pack_start($hbox, 0,0,0);

    my ($tv, $store) = $self->_crear_treeview(
        'Código', 'Nombre', 'Principio Activo', 'Laboratorio', 'Cantidad', 'Vencimiento', 'Precio'
    );
    $self->{med_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_meds() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_agregar_med() });
    $self->_refrescar_meds();
    return $vbox;
}

sub _refrescar_meds {
    my ($self) = @_;
    $self->{med_store}->clear();
    my $lista = Estado->get_instancia()->medicamentos;
    my $actual = $lista->{primero};
    while ($actual) {
        my $m = $actual->get_dato();
        my $iter = $self->{med_store}->append();
        $self->{med_store}->set($iter,
            0, $m->get_codigo(), 1, $m->get_nombre(), 2, $m->get_principioActivo(),
            3, $m->get_laboratorio(), 4, $m->get_cantidad(),
            5, $m->get_fechaVencimiento(), 6, sprintf("Q%.2f", $m->get_precio()),
        );
        $actual = $actual->get_siguiente();
    }
}

sub _dialog_agregar_med {
    my ($self) = @_;
    my $dialog = Gtk3::Dialog->new('Agregar Medicamento', $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $dialog->set_default_size(380, 320);
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);

    my @c = (['Código (MED...):', 'cod'], ['Nombre:', 'nom'], ['Principio activo:', 'pa'],
             ['Laboratorio:', 'lab'], ['Cantidad:', 'cant'], ['Precio Q:', 'pre'],
             ['Vencimiento:', 'fec'], ['Nivel mínimo:', 'niv']);
    my %e;
    for my $i (0..$#c) {
        $grid->attach(Gtk3::Label->new($c[$i][0]), 0, $i, 1, 1);
        $e{ $c[$i][1] } = Gtk3::Entry->new();
        $grid->attach($e{ $c[$i][1] }, 1, $i, 1, 1);
    }
    $dialog->get_content_area()->add($grid);
    $dialog->show_all();

    if ($dialog->run() eq 'ok') {
        require Medicamento;
        my $m = Medicamento->new({
            codigo => $e{cod}->get_text(), nombre => $e{nom}->get_text(),
            principioActivo => $e{pa}->get_text(), laboratorio => $e{lab}->get_text(),
            cantidad => $e{cant}->get_text() || 0, precio => $e{pre}->get_text() || 0,
            fechaVencimiento => $e{fec}->get_text(), nivelMinimo => $e{niv}->get_text() || 0,
        });
        Estado->get_instancia()->medicamentos->insertar($m);
        $self->_refrescar_meds();
    }
    $dialog->destroy();
}

# ---------------------------------------------------------------
# TAB: PROVEEDORES
# ---------------------------------------------------------------
sub _tab_proveedores {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    my $btn_ref = Gtk3::Button->new('↻ Refrescar');
    my $btn_add = Gtk3::Button->new('+ Agregar Proveedor');
    $hbox->pack_start($btn_add, 0,0,0);
    $hbox->pack_end($btn_ref, 0,0,0);
    $vbox->pack_start($hbox, 0,0,0);

    # Tabla de Matriz Dispersa (proveedor x fabricante)
    my $lbl = Gtk3::Label->new('Matriz Dispersa (Proveedor × Fabricante):');
    $lbl->set_halign('start');
    $vbox->pack_start($lbl, 0,0,4);

    my ($tv, $store) = $self->_crear_treeview('Proveedor', 'Fabricante', 'Cantidad Total');
    $self->{matriz_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_matriz() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_agregar_proveedor() });
    $self->_refrescar_matriz();
    return $vbox;
}

sub _refrescar_matriz {
    my ($self) = @_;
    $self->{matriz_store}->clear();
    for my $fila (Estado->get_instancia()->matriz->todos_como_lista()) {
        my $iter = $self->{matriz_store}->append();
        $self->{matriz_store}->set($iter, 0, $fila->[0], 1, $fila->[1], 2, "$fila->[2]");
    }
}

sub _dialog_agregar_proveedor {
    my ($self) = @_;
    my $dialog = Gtk3::Dialog->new('Agregar Proveedor', $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $dialog->set_default_size(320, 240);
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6); $grid->set_margin_start(15); $grid->set_margin_top(10);
    my @c = (['NIT:', 'nit'], ['Nombre:', 'nom'], ['Teléfono:', 'tel'], ['Dirección:', 'dir']);
    my %e;
    for my $i (0..$#c) {
        $grid->attach(Gtk3::Label->new($c[$i][0]), 0, $i, 1, 1);
        $e{ $c[$i][1] } = Gtk3::Entry->new();
        $grid->attach($e{ $c[$i][1] }, 1, $i, 1, 1);
    }
    $dialog->get_content_area()->add($grid);
    $dialog->show_all();
    if ($dialog->run() eq 'ok') {
        require Proveedor;
        my $p = Proveedor->new({ nit => $e{nit}->get_text(), nombre => $e{nom}->get_text(),
            telefono => $e{tel}->get_text(), direccion => $e{dir}->get_text() });
        Estado->get_instancia()->proveedores->agregar($p);
        $self->_msg("Proveedor registrado.");
    }
    $dialog->destroy();
}

# ---------------------------------------------------------------
# TAB: CARGA MASIVA
# ---------------------------------------------------------------
sub _tab_carga_masiva {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 12);
    $vbox->set_margin_start(20); $vbox->set_margin_end(20); $vbox->set_margin_top(20);

    # Sección 1: JSON Inventario
    my $frame1 = Gtk3::Frame->new('Carga Masiva de Inventario (JSON)');
    my $vb1 = Gtk3::Box->new('vertical', 6);
    $vb1->set_margin_start(10); $vb1->set_margin_top(8); $vb1->set_margin_bottom(8);
    $frame1->add($vb1);

    my $lbl_inv = Gtk3::Label->new('Formato: {"proveedor": [...]} - Carga MEDICAMENTOS, EQUIPOS y SUMINISTROS');
    $lbl_inv->set_halign('start');
    $vb1->pack_start($lbl_inv, 0,0,0);

    my $hb1 = Gtk3::Box->new('horizontal', 6);
    $self->{entry_json_inv} = Gtk3::Entry->new();
    $self->{entry_json_inv}->set_placeholder_text('Ruta al archivo JSON...');
    $self->{entry_json_inv}->set_hexpand(1);
    my $btn_sel1 = Gtk3::Button->new('📂 Seleccionar');
    my $btn_car1 = Gtk3::Button->new('⬆ Cargar');
    $hb1->pack_start($self->{entry_json_inv}, 1,1,0);
    $hb1->pack_start($btn_sel1, 0,0,0);
    $hb1->pack_start($btn_car1, 0,0,0);
    $vb1->pack_start($hb1, 0,0,0);
    $vbox->pack_start($frame1, 0,0,0);

    # Sección 2: JSON Usuarios
    my $frame2 = Gtk3::Frame->new('Carga Masiva de Usuarios (JSON)');
    my $vb2 = Gtk3::Box->new('vertical', 6);
    $vb2->set_margin_start(10); $vb2->set_margin_top(8); $vb2->set_margin_bottom(8);
    $frame2->add($vb2);

    my $lbl_usr = Gtk3::Label->new('Formato: {"usuarios": [...]} - Carga personal médico al AVL');
    $lbl_usr->set_halign('start');
    $vb2->pack_start($lbl_usr, 0,0,0);

    my $hb2 = Gtk3::Box->new('horizontal', 6);
    $self->{entry_json_usr} = Gtk3::Entry->new();
    $self->{entry_json_usr}->set_placeholder_text('Ruta al archivo JSON...');
    $self->{entry_json_usr}->set_hexpand(1);
    my $btn_sel2 = Gtk3::Button->new('📂 Seleccionar');
    my $btn_car2 = Gtk3::Button->new('⬆ Cargar');
    $hb2->pack_start($self->{entry_json_usr}, 1,1,0);
    $hb2->pack_start($btn_sel2, 0,0,0);
    $hb2->pack_start($btn_car2, 0,0,0);
    $vb2->pack_start($hb2, 0,0,0);
    $vbox->pack_start($frame2, 0,0,0);

    # Log de resultados
    $self->{log_buf} = Gtk3::TextBuffer->new();
    my $tv_log = Gtk3::TextView->new_with_buffer($self->{log_buf});
    $tv_log->set_editable(0);
    $tv_log->set_size_request(-1, 120);
    $vbox->pack_start($self->_en_scrolled($tv_log), 1,1,0);

    # Señales
    $btn_sel1->signal_connect(clicked => sub {
        my $f = $self->_elegir_archivo();
        $self->{entry_json_inv}->set_text($f) if $f;
    });
    $btn_car1->signal_connect(clicked => sub {
        my $ruta = $self->{entry_json_inv}->get_text();
        my ($ins, $omi, $err) = Estado->get_instancia()->cargar_json_inventario($ruta);
        if ($err) { $self->_log("ERROR: $err") }
        else { $self->_log("Inventario cargado: $ins insertados, $omi omitidos") }
        $self->_refrescar_bst(); $self->_refrescar_arbolb(); $self->_refrescar_meds(); $self->_refrescar_matriz();
    });
    $btn_sel2->signal_connect(clicked => sub {
        my $f = $self->_elegir_archivo();
        $self->{entry_json_usr}->set_text($f) if $f;
    });
    $btn_car2->signal_connect(clicked => sub {
        my $ruta = $self->{entry_json_usr}->get_text();
        my ($ins, $omi, $err) = Estado->get_instancia()->cargar_json_usuarios($ruta);
        if ($err) { $self->_log("ERROR: $err") }
        else { $self->_log("Usuarios cargados: $ins insertados, $omi omitidos") }
        $self->_refrescar_avl();
    });

    return $vbox;
}

# ---------------------------------------------------------------
# TAB: REPORTES GRAPHVIZ
# ---------------------------------------------------------------
sub _tab_reportes {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_margin_start(15); $vbox->set_margin_end(15); $vbox->set_margin_top(15);

    my $lbl = Gtk3::Label->new('Generar reportes Graphviz (PNG):');
    $lbl->set_halign('start');
    $vbox->pack_start($lbl, 0,0,0);

    my $btn_grid = Gtk3::Grid->new();
    $btn_grid->set_column_spacing(8); $btn_grid->set_row_spacing(8);
    $vbox->pack_start($btn_grid, 0,0,0);

    my @reportes = (
        ['Árbol AVL (Personal Médico)',    sub { $self->_gen_reporte('avl')  }],
        ['Árbol BST (Equipos)',            sub { $self->_gen_reporte('bst')  }],
        ['Árbol B Orden 4 (Suministros)',  sub { $self->_gen_reporte('b')    }],
        ['Matriz Dispersa',                sub { $self->_gen_reporte('mat')  }],
        ['Inventario Medicamentos',        sub { $self->_gen_reporte('meds') }],
        ['Proveedores',                    sub { $self->_gen_reporte('prov') }],
    );

    for my $i (0..$#reportes) {
        my $btn = Gtk3::Button->new("📊 " . $reportes[$i][0]);
        $btn->signal_connect(clicked => $reportes[$i][1]);
        $btn_grid->attach($btn, $i % 2, int($i/2), 1, 1);
    }

    # Área de imagen
    $self->{reporte_imagen} = Gtk3::Image->new();
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->add_with_viewport($self->{reporte_imagen});
    $vbox->pack_start($sw, 1, 1, 0);

    return $vbox;
}

sub _gen_reporte {
    my ($self, $tipo) = @_;
    my $estado = Estado->get_instancia();
    my $dir    = $estado->dir_reportes();
    my $png;

    if    ($tipo eq 'avl')  { $png = $estado->usuarios->generar_dot("$dir/reporte_avl.dot")  }
    elsif ($tipo eq 'bst')  { $png = $estado->equipos->generar_dot("$dir/reporte_bst.dot")   }
    elsif ($tipo eq 'b')    { $png = $estado->suministros->generar_dot("$dir/reporte_b.dot") }
    elsif ($tipo eq 'mat')  { $png = $estado->matriz->generar_dot("$dir/reporte_matriz.dot") }
    elsif ($tipo eq 'meds') { $png = $estado->medicamentos->generar_dot("$dir/reporte_meds.dot") }
    elsif ($tipo eq 'prov') { $png = $estado->proveedores->generar_dot("$dir/reporte_prov.dot")  }

    if ($png && -e $png) {
        $self->{reporte_imagen}->set_from_file($png);
        $self->{reporte_imagen}->show();
    } else {
        $self->_log("No se pudo generar el reporte. ¿Está instalado Graphviz? (brew install graphviz)");
    }
}

# ---------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------
sub _msg {
    my ($self, $texto) = @_;
    my $d = Gtk3::MessageDialog->new($self->{win}, 'destroy-with-parent', 'info', 'ok', $texto);
    $d->run(); $d->destroy();
}

sub _log {
    my ($self, $texto) = @_;
    my $buf = $self->{log_buf};
    my $end = $buf->get_end_iter();
    $buf->insert($end, "$texto\n");
}

sub _elegir_archivo {
    my ($self) = @_;
    my $d = Gtk3::FileChooserDialog->new('Seleccionar archivo', $self->{win},
        'open', 'gtk-cancel', 'cancel', 'gtk-open', 'accept');
    my $filter = Gtk3::FileFilter->new();
    $filter->add_pattern('*.json');
    $filter->set_name('Archivos JSON');
    $d->add_filter($filter);
    my $archivo = undef;
    $archivo = $d->get_filename() if $d->run() eq 'accept';
    $d->destroy();
    return $archivo;
}

1;
