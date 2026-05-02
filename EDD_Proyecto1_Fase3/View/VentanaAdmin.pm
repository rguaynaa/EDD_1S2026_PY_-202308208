package VentanaAdmin;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Gtk3 -init;

use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/model";
use EstadoF3;

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
    $win->set_title('EDD MedTrack F3 - Administrador');
    $win->set_default_size(1100, 720);
    $win->set_position('center');
    $win->signal_connect(destroy => sub {
        $self->{ventana_login}->show_all() if defined $self->{ventana_login};
    });

    my $vbox = Gtk3::Box->new('vertical', 0);
    $win->add($vbox);
    $vbox->pack_start($self->_crear_header(), 0, 0, 0);

    my $nb = Gtk3::Notebook->new();
    $vbox->pack_start($nb, 1, 1, 0);

    $nb->append_page($self->_tab_personal_medico(),  Gtk3::Label->new('Personal (AVL)'));
    $nb->append_page($self->_tab_tabla_hash(),        Gtk3::Label->new('Directorio Hash'));
    $nb->append_page($self->_tab_grafo_admin(),       Gtk3::Label->new('Red (Grafo)'));
    $nb->append_page($self->_tab_solicitudes(),       Gtk3::Label->new('Solicitudes'));
    $nb->append_page($self->_tab_inventario(),        Gtk3::Label->new('Inventario'));
    $nb->append_page($self->_tab_carga_masiva(),      Gtk3::Label->new('Carga Masiva'));
    $nb->append_page($self->_tab_reportes(),          Gtk3::Label->new('Reportes'));

    $win->show_all();
}

sub _crear_header {
    my ($self) = @_;
    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->override_background_color('normal', Gtk3::Gdk::RGBA::parse('#1a2744'));
    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span foreground="white" size="large" weight="bold"> EDD MEDTRACK F3 </span>');
    $titulo->set_margin_start(15); $titulo->set_margin_top(10); $titulo->set_margin_bottom(10);
    $hbox->pack_start($titulo, 0, 0, 0);
    my $lbl = Gtk3::Label->new('');
    $lbl->set_markup('<span foreground="#e67e22" size="medium"> Administrador </span>');
    $hbox->pack_end($lbl, 0, 0, 15);
    return $hbox;
}

# ---------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------
sub _crear_treeview {
    my ($self, @cols) = @_;
    my $store = Gtk3::ListStore->new(map { 'Glib::String' } @cols);
    my $tv    = Gtk3::TreeView->new($store);
    $tv->set_rules_hint(1);
    for my $i (0..$#cols) {
        my $r   = Gtk3::CellRendererText->new();
        my $col = Gtk3::TreeViewColumn->new_with_attributes($cols[$i], $r, text => $i);
        $col->set_resizable(1); $col->set_sort_column_id($i);
        $tv->append_column($col);
    }
    return ($tv, $store);
}

sub _en_scrolled {
    my ($self, $w) = @_;
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->add($w);
    return $sw;
}

sub _msg {
    my ($self, $txt) = @_;
    my $d = Gtk3::MessageDialog->new($self->{win}, 'destroy-with-parent', 'info', 'ok', $txt);
    $d->run(); $d->destroy();
}

sub _log {
    my ($self, $txt) = @_;
    return unless defined $self->{log_buf};
    my $end = $self->{log_buf}->get_end_iter();
    $self->{log_buf}->insert($end, "$txt\n");
}

# ---------------------------------------------------------------
# TAB: PERSONAL MEDICO (AVL) con asignacion de departamento
# ---------------------------------------------------------------
sub _tab_personal_medico {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text('Núm. colegio...');
    my $btn_add = Gtk3::Button->new('+ Agregar');
    my $btn_bus = Gtk3::Button->new('🔍 Buscar');
    my $btn_del = Gtk3::Button->new('✕ Eliminar');
    my $btn_dep = Gtk3::Button->new('🏢 Asignar Depto');
    my $btn_rec = Gtk3::Button->new('↕ Recorridos');
    my $btn_ref = Gtk3::Button->new('↻');

    $hbox->pack_start($btn_add, 0,0,0); $hbox->pack_start($entry, 0,0,0);
    $hbox->pack_start($btn_bus, 0,0,0); $hbox->pack_start($btn_del, 0,0,0);
    $hbox->pack_start($btn_dep, 0,0,0); $hbox->pack_start($btn_rec, 0,0,0);
    $hbox->pack_end($btn_ref,   0,0,0);

    my ($tv, $store) = $self->_crear_treeview(
        'Núm. Colegio', 'Nombre', 'Tipo', 'Departamento', 'Especialidad'
    );
    $self->{avl_store} = $store; $self->{avl_tv} = $tv;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    # Panel pendientes
    my $lbl_pend = Gtk3::Label->new('');
    $lbl_pend->set_markup('<b>⚠ Usuarios sin departamento (SIN-DEP):</b>');
    $lbl_pend->set_halign('start');
    $vbox->pack_start($lbl_pend, 0, 0, 4);

    my ($tv2, $store2) = $self->_crear_treeview('Núm. Colegio', 'Nombre', 'Tipo', 'Especialidad');
    $self->{pendientes_store} = $store2;
    $tv2->set_size_request(-1, 100);
    $vbox->pack_start($self->_en_scrolled($tv2), 0, 0, 0);

    # Area recorridos
    my $tv_rec = Gtk3::TextView->new(); $tv_rec->set_editable(0); $tv_rec->set_size_request(-1, 70);
    $self->{avl_rec_buf} = $tv_rec->get_buffer();
    $vbox->pack_start($self->_en_scrolled($tv_rec), 0, 0, 0);

    # Señales
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_avl() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_agregar_usuario() });
    $btn_del->signal_connect(clicked => sub {
        my $col = $entry->get_text(); return unless $col;
        my $ok = EstadoF3->get_instancia()->eliminar_usuario($col);
        $self->_msg($ok ? "Usuario $col eliminado." : "No encontrado: $col");
        $self->_refrescar_avl() if $ok;
    });
    $btn_bus->signal_connect(clicked => sub {
        my $col = $entry->get_text();
        my $u = EstadoF3->get_instancia()->usuarios->buscar($col);
        $self->_msg($u ? $u->to_string() : "No encontrado: $col");
    });
    $btn_dep->signal_connect(clicked => sub {
        my $col = $entry->get_text();
        $self->_dialog_asignar_dep($col) if $col;
    });
    $btn_rec->signal_connect(clicked => sub {
        my $avl = EstadoF3->get_instancia()->usuarios;
        my $t = "=== INORDEN ===\n" . (join(", ", map { $_->get_numero_colegio() } $avl->inorden()) || "(vacío)");
        $t   .= "\n\n=== PREORDEN ===\n" . (join(", ", map { $_->get_numero_colegio() } $avl->preorden()) || "(vacío)");
        $t   .= "\n\n=== POSTORDEN ===\n" . (join(", ", map { $_->get_numero_colegio() } $avl->postorden()) || "(vacío)");
        $self->{avl_rec_buf}->set_text($t);
    });

    $self->_refrescar_avl();
    return $vbox;
}

sub _refrescar_avl {
    my ($self) = @_;
    $self->{avl_store}->clear();
    $self->{pendientes_store}->clear();
    for my $u (EstadoF3->get_instancia()->usuarios->inorden()) {
        my $dep = $u->get_departamento() // 'SIN-DEP';
        my $iter = $self->{avl_store}->append();
        $self->{avl_store}->set($iter,
            0, $u->get_numero_colegio(), 1, $u->get_nombre_completo(),
            2, $u->get_tipo_usuario(),   3, $dep,
            4, $u->get_especialidad() || 'N/A',
        );
        if ($dep eq 'SIN-DEP') {
            my $iter2 = $self->{pendientes_store}->append();
            $self->{pendientes_store}->set($iter2,
                0, $u->get_numero_colegio(), 1, $u->get_nombre_completo(),
                2, $u->get_tipo_usuario(),   3, $u->get_especialidad() || 'N/A',
            );
        }
    }
}

sub _dialog_agregar_usuario {
    my ($self) = @_;
    my $d = Gtk3::Dialog->new('Agregar Usuario', $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $d->set_default_size(380, 340);
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);

    my %e;
    my @f = (['Núm. Colegio:', 'col'], ['Nombre completo:', 'nom'],
              ['Especialidad:', 'esp'], ['Contraseña:', 'pass']);
    for my $i (0..$#f) {
        $grid->attach(Gtk3::Label->new($f[$i][0]), 0, $i, 1, 1);
        my $en = Gtk3::Entry->new();
        $en->set_visibility(0) if $f[$i][1] eq 'pass';
        $e{ $f[$i][1] } = $en;
        $grid->attach($en, 1, $i, 1, 1);
    }

    my $ct = Gtk3::ComboBoxText->new();
    for my $t ('TIPO-01','TIPO-02','TIPO-03','TIPO-04') { $ct->append_text($t) }
    $ct->set_active(0);
    $grid->attach(Gtk3::Label->new('Tipo:'), 0, 4, 1, 1);
    $grid->attach($ct, 1, 4, 1, 1);

    my $cd = Gtk3::ComboBoxText->new();
    for my $dep ('DEP-MED','DEP-CIR','DEP-LAB','DEP-FAR','SIN-DEP') { $cd->append_text($dep) }
    $cd->set_active(0);
    $grid->attach(Gtk3::Label->new('Departamento:'), 0, 5, 1, 1);
    $grid->attach($cd, 1, 5, 1, 1);

    $d->get_content_area()->add($grid);
    $d->show_all();

    if ($d->run() eq 'ok') {
        require Usuario;
        my $u = Usuario->new({
            numero_colegio  => $e{col}->get_text(),
            nombre_completo => $e{nom}->get_text(),
            tipo_usuario    => $ct->get_active_text(),
            departamento    => $cd->get_active_text(),
            especialidad    => $e{esp}->get_text(),
            contrasena      => $e{pass}->get_text(),
        });
        my $ok = EstadoF3->get_instancia()->registrar_usuario($u);
        $self->_msg($ok ? "Usuario agregado." : "Error: colegio ya existe.");
        $self->_refrescar_avl() if $ok;
    }
    $d->destroy();
}

sub _dialog_asignar_dep {
    my ($self, $col) = @_;
    my $u = EstadoF3->get_instancia()->usuarios->buscar($col);
    unless ($u) { $self->_msg("Usuario no encontrado: $col"); return }

    my $d = Gtk3::Dialog->new("Asignar Departamento - $col", $self->{win},
        'destroy-with-parent', 'gtk-ok', 'ok', 'gtk-cancel', 'cancel');
    $d->set_default_size(320, 160);
    my $vb = Gtk3::Box->new('vertical', 8);
    $vb->set_margin_start(15); $vb->set_margin_top(10);

    my $lbl = Gtk3::Label->new("Usuario: " . $u->get_nombre_completo());
    $lbl->set_halign('start');
    $vb->pack_start($lbl, 0, 0, 0);

    my $combo = Gtk3::ComboBoxText->new();
    for my $dep ('DEP-MED','DEP-CIR','DEP-LAB','DEP-FAR','DEP-ADM','SIN-DEP') {
        $combo->append_text($dep);
    }
    $combo->set_active(0);
    $vb->pack_start($combo, 0, 0, 0);
    $d->get_content_area()->add($vb);
    $d->show_all();

    if ($d->run() eq 'ok') {
        my $dep = $combo->get_active_text();
        EstadoF3->get_instancia()->asignar_departamento($col, $dep);
        $self->_msg("Departamento '$dep' asignado a $col.");
        $self->_refrescar_avl();
    }
    $d->destroy();
}

# ---------------------------------------------------------------
# TAB: TABLA HASH
# ---------------------------------------------------------------
sub _tab_tabla_hash {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 8);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $lbl = Gtk3::Label->new('Consultar por tipo:');
    $hbox->pack_start($lbl, 0, 0, 0);

    my $combo = Gtk3::ComboBoxText->new();
    for my $t ('TIPO-01 - Médico General', 'TIPO-02 - Especialista', 'TIPO-03 - Enfermero/a', 'TIPO-04 - Téc. Lab') {
        $combo->append_text($t);
    }
    $combo->set_active(0);
    $hbox->pack_start($combo, 0, 0, 0);

    my $btn_bus = Gtk3::Button->new('🔍 Consultar');
    my $btn_ref = Gtk3::Button->new('↻ Todos');
    $hbox->pack_start($btn_bus, 0, 0, 0);
    $hbox->pack_start($btn_ref, 0, 0, 0);

    my ($tv, $store) = $self->_crear_treeview('Núm. Colegio', 'Nombre', 'Tipo', 'Departamento', 'Especialidad');
    $self->{hash_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    # Info estadísticas
    $self->{hash_info} = Gtk3::Label->new('');
    $self->{hash_info}->set_halign('start');
    $vbox->pack_start($self->{hash_info}, 0, 0, 0);

    $btn_bus->signal_connect(clicked => sub {
        my $txt = $combo->get_active_text() // '';
        my ($tipo) = $txt =~ /^(TIPO-\d+)/;
        return unless $tipo;
        $self->{hash_store}->clear();
        for my $u (EstadoF3->get_instancia()->tabla_hash->buscar_por_tipo($tipo)) {
            my $iter = $self->{hash_store}->append();
            $self->{hash_store}->set($iter,
                0, $u->get_numero_colegio(), 1, $u->get_nombre_completo(),
                2, $u->get_tipo_usuario(),   3, $u->get_departamento(),
                4, $u->get_especialidad() || 'N/A',
            );
        }
        $self->_actualizar_info_hash();
    });

    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_hash_todos() });
    $self->_refrescar_hash_todos();
    return $vbox;
}

sub _refrescar_hash_todos {
    my ($self) = @_;
    $self->{hash_store}->clear();
    for my $tipo ('TIPO-01','TIPO-02','TIPO-03','TIPO-04') {
        for my $u (EstadoF3->get_instancia()->tabla_hash->buscar_por_tipo($tipo)) {
            my $iter = $self->{hash_store}->append();
            $self->{hash_store}->set($iter,
                0, $u->get_numero_colegio(), 1, $u->get_nombre_completo(),
                2, $u->get_tipo_usuario(),   3, $u->get_departamento() // 'SIN-DEP',
                4, $u->get_especialidad() || 'N/A',
            );
        }
    }
    $self->_actualizar_info_hash();
}

sub _actualizar_info_hash {
    my ($self) = @_;
    my $th = EstadoF3->get_instancia()->tabla_hash;
    my $txt = sprintf("Total: %d usuarios | Colisiones: %d | Tamaño tabla: %d slots",
        $th->get_total(), $th->get_colisiones(), $th->get_tamanio());
    $self->{hash_info}->set_text($txt) if defined $self->{hash_info};
}

# ---------------------------------------------------------------
# TAB: GRAFO / RED DE COLABORACION (admin)
# ---------------------------------------------------------------
sub _tab_grafo_admin {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $ea = Gtk3::Entry->new(); $ea->set_placeholder_text('Colegio A...');
    my $eb = Gtk3::Entry->new(); $eb->set_placeholder_text('Colegio B...');
    my $btn_add = Gtk3::Button->new('+ Añadir arista');
    my $btn_del = Gtk3::Button->new('✕ Quitar arista');
    my $btn_ref = Gtk3::Button->new('↻ Refrescar');

    $hbox->pack_start(Gtk3::Label->new('A:'), 0,0,0);
    $hbox->pack_start($ea, 0,0,0);
    $hbox->pack_start(Gtk3::Label->new('B:'), 0,0,0);
    $hbox->pack_start($eb, 0,0,0);
    $hbox->pack_start($btn_add, 0,0,0);
    $hbox->pack_start($btn_del, 0,0,0);
    $hbox->pack_end($btn_ref,   0,0,0);

    # Lista de adyacencia textual
    my $lbl = Gtk3::Label->new('');
    $lbl->set_markup('<b>Lista de Adyacencia:</b>');
    $lbl->set_halign('start');
    $vbox->pack_start($lbl, 0, 0, 2);

    my $tv_adj = Gtk3::TextView->new(); $tv_adj->set_editable(0);
    $self->{adj_buf} = $tv_adj->get_buffer();
    $tv_adj->set_size_request(-1, 200);
    $vbox->pack_start($self->_en_scrolled($tv_adj), 0, 0, 0);

    # Solicitudes pendientes globales
    my $lbl2 = Gtk3::Label->new('');
    $lbl2->set_markup('<b>Solicitudes de colaboración pendientes:</b>');
    $lbl2->set_halign('start');
    $vbox->pack_start($lbl2, 0, 0, 2);

    my ($tv_sol, $store_sol) = $self->_crear_treeview('Solicitante', 'Receptor', 'Estado');
    $self->{sol_store} = $store_sol;
    $tv_sol->set_size_request(-1, 120);
    $vbox->pack_start($self->_en_scrolled($tv_sol), 0, 0, 0);

    $btn_add->signal_connect(clicked => sub {
        my $a = $ea->get_text(); my $b = $eb->get_text();
        return unless $a && $b;
        EstadoF3->get_instancia()->grafo->agregar_arista($a, $b);
        $self->_refrescar_grafo_admin();
    });
    $btn_del->signal_connect(clicked => sub {
        my $a = $ea->get_text(); my $b = $eb->get_text();
        return unless $a && $b;
        EstadoF3->get_instancia()->grafo->eliminar_arista($a, $b);
        $self->_refrescar_grafo_admin();
    });
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_grafo_admin() });
    $self->_refrescar_grafo_admin();
    return $vbox;
}

sub _refrescar_grafo_admin {
    my ($self) = @_;
    my $grafo = EstadoF3->get_instancia()->grafo;
    $self->{adj_buf}->set_text($grafo->lista_adyacencia_texto());

    $self->{sol_store}->clear();
    for my $s (@{ $grafo->{solicitudes} }) {
        my $iter = $self->{sol_store}->append();
        $self->{sol_store}->set($iter,
            0, $s->{solicitante}, 1, $s->{receptor}, 2, $s->{estado}
        );
    }
}

# ---------------------------------------------------------------
# TAB: SOLICITUDES DE REABASTECIMIENTO
# ---------------------------------------------------------------
sub _tab_solicitudes {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_end(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);

    my $btn_apr = Gtk3::Button->new('✓ Aprobar primera');
    my $btn_rec = Gtk3::Button->new('✕ Rechazar primera');
    my $btn_ref = Gtk3::Button->new('↻ Refrescar');
    $hbox->pack_start($btn_apr, 0,0,0);
    $hbox->pack_start($btn_rec, 0,0,0);
    $hbox->pack_end($btn_ref,   0,0,0);

    $self->{sol_info} = Gtk3::Label->new('');
    $self->{sol_info}->set_halign('start');
    $vbox->pack_start($self->{sol_info}, 0, 0, 2);

    my ($tv, $store) = $self->_crear_treeview(
        'ID', 'Departamento', 'Tipo', 'Código', 'Nombre', 'Cantidad', 'Solicitante', 'Fecha', 'Estado'
    );
    $self->{req_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    # Info Merkle
    $self->{merkle_info} = Gtk3::Label->new('');
    $self->{merkle_info}->set_halign('start');
    $vbox->pack_start($self->{merkle_info}, 0, 0, 0);

    $btn_apr->signal_connect(clicked => sub {
        my ($ok, $msg) = EstadoF3->get_instancia()->aprobar_solicitud();
        $self->_msg($msg);
        $self->_refrescar_solicitudes();
    });
    $btn_rec->signal_connect(clicked => sub {
        my $ok = EstadoF3->get_instancia()->rechazar_solicitud();
        $self->_msg($ok ? "Solicitud rechazada." : "No hay solicitudes pendientes.");
        $self->_refrescar_solicitudes();
    });
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_solicitudes() });
    $self->_refrescar_solicitudes();
    return $vbox;
}

sub _refrescar_solicitudes {
    my ($self) = @_;
    my $lista = EstadoF3->get_instancia()->solicitudes;
    $self->{req_store}->clear();
    my $n = $lista->get_tamanio();
    $self->{sol_info}->set_text("Solicitudes en cola: $n");

    for my $s ($lista->todas()) {
        my $iter = $self->{req_store}->append();
        $self->{req_store}->set($iter,
            0, $s->get_id(),           1, $s->get_departamento(),
            2, $s->get_tipo_item(),    3, $s->get_codigo(),
            4, $s->get_nombre(),       5, $s->get_cantidad(),
            6, $s->get_solicitante_col(), 7, $s->get_timestamp(),
            8, $s->get_estado(),
        );
    }

    my $merkle = EstadoF3->get_instancia()->merkle;
    my $hash   = $merkle->get_hash_raiz();
    my $integ  = $merkle->verificar_integridad() ? "✓ ÍNTEGRO" : "✗ ALTERADO";
    $self->{merkle_info}->set_text("Árbol Merkle — Hash raíz: $hash | Estado: $integ");
}

# ---------------------------------------------------------------
# TAB: INVENTARIO (BST, Árbol B, Lista Doble) compacto
# ---------------------------------------------------------------
sub _tab_inventario {
    my ($self) = @_;
    my $nb = Gtk3::Notebook->new();

    $nb->append_page($self->_sub_equipos(),      Gtk3::Label->new('Equipos (BST)'));
    $nb->append_page($self->_sub_suministros(),  Gtk3::Label->new('Suministros (B)'));
    $nb->append_page($self->_sub_medicamentos(), Gtk3::Label->new('Medicamentos'));
    $nb->append_page($self->_sub_proveedores(),  Gtk3::Label->new('Proveedores'));

    return $nb;
}

sub _sub_equipos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text('Código EQU...');
    my $btn_add = Gtk3::Button->new('+ Agregar');
    my $btn_bus = Gtk3::Button->new('🔍');
    my $btn_del = Gtk3::Button->new('✕');
    my $btn_ref = Gtk3::Button->new('↻');
    $hbox->pack_start($btn_add,0,0,0); $hbox->pack_start($entry,0,0,0);
    $hbox->pack_start($btn_bus,0,0,0); $hbox->pack_start($btn_del,0,0,0);
    $hbox->pack_end($btn_ref,0,0,0);
    my ($tv, $store) = $self->_crear_treeview('Código','Nombre','Fabricante','Precio','Cantidad','Fecha','Niv.Min');
    $self->{bst_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_bst() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_equipo() });
    $btn_bus->signal_connect(clicked => sub {
        my $e = EstadoF3->get_instancia()->equipos->buscar($entry->get_text());
        $self->_msg($e ? $e->to_string() : "No encontrado");
    });
    $btn_del->signal_connect(clicked => sub {
        my $ok = EstadoF3->get_instancia()->equipos->eliminar($entry->get_text());
        $self->_msg($ok ? "Eliminado." : "No encontrado."); $self->_refrescar_bst() if $ok;
    });
    $self->_refrescar_bst(); return $vbox;
}

sub _refrescar_bst {
    my ($self) = @_;
    return unless defined $self->{bst_store};
    $self->{bst_store}->clear();
    for my $e (EstadoF3->get_instancia()->equipos->inorden()) {
        my $iter = $self->{bst_store}->append();
        $self->{bst_store}->set($iter,
            0,$e->get_codigo(),1,$e->get_nombre(),2,$e->get_fabricante(),
            3,sprintf("Q%.2f",$e->get_precio()),4,$e->get_cantidad(),
            5,$e->get_fecha_ingreso(),6,$e->get_nivel_minimo());
    }
}

sub _dialog_equipo {
    my ($self) = @_;
    my $d = Gtk3::Dialog->new('Agregar Equipo',$self->{win},'destroy-with-parent','gtk-ok','ok','gtk-cancel','cancel');
    $d->set_default_size(340,280);
    my $grid = Gtk3::Grid->new(); $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);
    my @c = (['Código:','cod'],['Nombre:','nom'],['Fabricante:','fab'],['Precio Q:','pre'],['Cantidad:','cant'],['Fecha ingreso:','fec'],['Nivel mínimo:','niv']);
    my %e;
    for my $i (0..$#c) { $grid->attach(Gtk3::Label->new($c[$i][0]),0,$i,1,1); $e{$c[$i][1]}=Gtk3::Entry->new(); $grid->attach($e{$c[$i][1]},1,$i,1,1); }
    $d->get_content_area()->add($grid); $d->show_all();
    if ($d->run() eq 'ok') {
        require Equipo;
        EstadoF3->get_instancia()->equipos->insertar(Equipo->new({
            codigo=>$e{cod}->get_text(),nombre=>$e{nom}->get_text(),fabricante=>$e{fab}->get_text(),
            precio=>$e{pre}->get_text()||0,cantidad=>$e{cant}->get_text()||0,
            fecha_ingreso=>$e{fec}->get_text(),nivel_minimo=>$e{niv}->get_text()||0,
        }));
        $self->_refrescar_bst();
    }
    $d->destroy();
}

sub _sub_suministros {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text('Código SUM...');
    my $btn_add = Gtk3::Button->new('+ Agregar');
    my $btn_bus = Gtk3::Button->new('🔍');
    my $btn_del = Gtk3::Button->new('✕');
    my $btn_ref = Gtk3::Button->new('↻');
    $hbox->pack_start($btn_add,0,0,0); $hbox->pack_start($entry,0,0,0);
    $hbox->pack_start($btn_bus,0,0,0); $hbox->pack_start($btn_del,0,0,0);
    $hbox->pack_end($btn_ref,0,0,0);
    my ($tv,$store) = $self->_crear_treeview('Código','Nombre','Fabricante','Precio','Cantidad','Vencimiento','Niv.Min');
    $self->{b_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_b() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_suministro() });
    $btn_bus->signal_connect(clicked => sub {
        my $s = EstadoF3->get_instancia()->suministros->buscar($entry->get_text());
        $self->_msg($s ? $s->to_string() : "No encontrado");
    });
    $btn_del->signal_connect(clicked => sub {
        my $ok = EstadoF3->get_instancia()->suministros->eliminar($entry->get_text());
        $self->_msg($ok ? "Eliminado." : "No encontrado."); $self->_refrescar_b() if $ok;
    });
    $self->_refrescar_b(); return $vbox;
}

sub _refrescar_b {
    my ($self) = @_;
    return unless defined $self->{b_store};
    $self->{b_store}->clear();
    for my $s (EstadoF3->get_instancia()->suministros->inorden()) {
        my $iter = $self->{b_store}->append();
        $self->{b_store}->set($iter,
            0,$s->get_codigo(),1,$s->get_nombre(),2,$s->get_fabricante(),
            3,sprintf("Q%.2f",$s->get_precio()),4,$s->get_cantidad(),
            5,$s->get_fecha_vencimiento(),6,$s->get_nivel_minimo());
    }
}

sub _dialog_suministro {
    my ($self) = @_;
    my $d = Gtk3::Dialog->new('Agregar Suministro',$self->{win},'destroy-with-parent','gtk-ok','ok','gtk-cancel','cancel');
    $d->set_default_size(340,280);
    my $grid = Gtk3::Grid->new(); $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(15); $grid->set_margin_top(10);
    my @c = (['Código:','cod'],['Nombre:','nom'],['Fabricante:','fab'],['Precio Q:','pre'],['Cantidad:','cant'],['Vencimiento:','fec'],['Nivel mínimo:','niv']);
    my %e;
    for my $i (0..$#c) { $grid->attach(Gtk3::Label->new($c[$i][0]),0,$i,1,1); $e{$c[$i][1]}=Gtk3::Entry->new(); $grid->attach($e{$c[$i][1]},1,$i,1,1); }
    $d->get_content_area()->add($grid); $d->show_all();
    if ($d->run() eq 'ok') {
        require Suministro;
        EstadoF3->get_instancia()->suministros->insertar(Suministro->new({
            codigo=>$e{cod}->get_text(),nombre=>$e{nom}->get_text(),fabricante=>$e{fab}->get_text(),
            precio=>$e{pre}->get_text()||0,cantidad=>$e{cant}->get_text()||0,
            fecha_vencimiento=>$e{fec}->get_text(),nivel_minimo=>$e{niv}->get_text()||0,
        }));
        $self->_refrescar_b();
    }
    $d->destroy();
}

sub _sub_medicamentos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    my $btn_add = Gtk3::Button->new('+ Agregar');
    my $btn_ref = Gtk3::Button->new('↻');
    $hbox->pack_start($btn_add,0,0,0); $hbox->pack_end($btn_ref,0,0,0);
    my ($tv,$store) = $self->_crear_treeview('Código','Nombre','PA','Laboratorio','Cantidad','Vencimiento','Precio');
    $self->{med_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_meds() });
    $btn_add->signal_connect(clicked => sub { $self->_dialog_med() });
    $self->_refrescar_meds(); return $vbox;
}

sub _refrescar_meds {
    my ($self) = @_;
    return unless defined $self->{med_store};
    $self->{med_store}->clear();
    my $actual = EstadoF3->get_instancia()->medicamentos->{primero};
    while ($actual) {
        my $m = $actual->get_dato();
        my $iter = $self->{med_store}->append();
        $self->{med_store}->set($iter,
            0,$m->get_codigo(),1,$m->get_nombre(),2,$m->get_principioActivo(),
            3,$m->get_laboratorio(),4,$m->get_cantidad(),
            5,$m->get_fechaVencimiento(),6,sprintf("Q%.2f",$m->get_precio()));
        $actual = $actual->get_siguiente();
    }
}

sub _dialog_med {
    my ($self) = @_;
    my $d = Gtk3::Dialog->new('Agregar Medicamento',$self->{win},'destroy-with-parent','gtk-ok','ok','gtk-cancel','cancel');
    $d->set_default_size(360,320);
    my $grid = Gtk3::Grid->new(); $grid->set_column_spacing(8); $grid->set_row_spacing(6); $grid->set_margin_start(15); $grid->set_margin_top(10);
    my @c = (['Código:','cod'],['Nombre:','nom'],['Principio activo:','pa'],['Laboratorio:','lab'],['Cantidad:','cant'],['Precio Q:','pre'],['Vencimiento:','fec'],['Nivel mínimo:','niv']);
    my %e;
    for my $i (0..$#c) { $grid->attach(Gtk3::Label->new($c[$i][0]),0,$i,1,1); $e{$c[$i][1]}=Gtk3::Entry->new(); $grid->attach($e{$c[$i][1]},1,$i,1,1); }
    $d->get_content_area()->add($grid); $d->show_all();
    if ($d->run() eq 'ok') {
        require Medicamento;
        EstadoF3->get_instancia()->medicamentos->insertar(Medicamento->new({
            codigo=>$e{cod}->get_text(),nombre=>$e{nom}->get_text(),
            principioActivo=>$e{pa}->get_text(),laboratorio=>$e{lab}->get_text(),
            cantidad=>$e{cant}->get_text()||0,precio=>$e{pre}->get_text()||0,
            fechaVencimiento=>$e{fec}->get_text(),nivelMinimo=>$e{niv}->get_text()||0,
        }));
        $self->_refrescar_meds();
    }
    $d->destroy();
}

sub _sub_proveedores {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    my $btn_ref = Gtk3::Button->new('↻ Refrescar');
    $hbox->pack_end($btn_ref, 0, 0, 0);
    my ($tv,$store) = $self->_crear_treeview('Proveedor','Fabricante','Cantidad Total');
    $self->{matriz_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $btn_ref->signal_connect(clicked => sub { $self->_refrescar_matriz() });
    $self->_refrescar_matriz(); return $vbox;
}

sub _refrescar_matriz {
    my ($self) = @_;
    return unless defined $self->{matriz_store};
    $self->{matriz_store}->clear();
    for my $f (EstadoF3->get_instancia()->matriz->todos_como_lista()) {
        my $iter = $self->{matriz_store}->append();
        $self->{matriz_store}->set($iter, 0,$f->[0], 1,$f->[1], 2,"$f->[2]");
    }
}

# ---------------------------------------------------------------
# TAB: CARGA MASIVA
# ---------------------------------------------------------------
sub _tab_carga_masiva {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 12);
    $vbox->set_margin_start(20); $vbox->set_margin_end(20); $vbox->set_margin_top(15);

    my @secciones = (
        ['Inventario (JSON)', 'json_inv', 'cargar_json_inventario'],
        ['Usuarios (JSON)',   'json_usr', 'cargar_json_usuarios'],
        ['Relaciones Grafo (JSON)', 'json_rel', 'cargar_json_relaciones'],
    );

    for my $sec (@secciones) {
        my $frame = Gtk3::Frame->new("Carga: $sec->[0]");
        my $vb = Gtk3::Box->new('vertical', 6);
        $vb->set_margin_start(10); $vb->set_margin_top(6); $vb->set_margin_bottom(6);
        $frame->add($vb);
        my $hb = Gtk3::Box->new('horizontal', 6);
        $self->{"entry_$sec->[1]"} = Gtk3::Entry->new();
        $self->{"entry_$sec->[1]"}->set_placeholder_text('Ruta al archivo JSON...');
        $self->{"entry_$sec->[1]"}->set_hexpand(1);
        my $btn_sel = Gtk3::Button->new('📂 Seleccionar');
        my $btn_car = Gtk3::Button->new('⬆ Cargar');
        $hb->pack_start($self->{"entry_$sec->[1]"}, 1,1,0);
        $hb->pack_start($btn_sel, 0,0,0);
        $hb->pack_start($btn_car, 0,0,0);
        $vb->pack_start($hb, 0,0,0);
        $vbox->pack_start($frame, 0,0,0);

        my $metodo = $sec->[2];
        my $entry_key = "entry_$sec->[1]";

        $btn_sel->signal_connect(clicked => sub {
            my $f = $self->_elegir_archivo();
            $self->{$entry_key}->set_text($f) if $f;
        });
        $btn_car->signal_connect(clicked => sub {
            my $ruta = $self->{$entry_key}->get_text();
            my ($a, $b, $err) = EstadoF3->get_instancia()->$metodo($ruta);
            if ($err && $err !~ /^Rechazadas/) {
                $self->_log("ERROR ($sec->[0]): $err");
            } else {
                $self->_log("$sec->[0] cargado: $a ok, $b omitidos. " . ($err//''));
            }
            $self->_refrescar_avl(); $self->_refrescar_hash_todos();
            $self->_refrescar_bst(); $self->_refrescar_b();
            $self->_refrescar_meds(); $self->_refrescar_matriz();
            $self->_refrescar_grafo_admin();
        });
    }

    # Log
    $self->{log_buf} = Gtk3::TextBuffer->new();
    my $tv_log = Gtk3::TextView->new_with_buffer($self->{log_buf});
    $tv_log->set_editable(0); $tv_log->set_size_request(-1, 120);
    $vbox->pack_start($self->_en_scrolled($tv_log), 1,1,0);

    return $vbox;
}

sub _elegir_archivo {
    my ($self) = @_;
    my $d = Gtk3::FileChooserDialog->new('Seleccionar archivo', $self->{win},
        'open', 'gtk-cancel','cancel','gtk-open','accept');
    my $filter = Gtk3::FileFilter->new();
    $filter->add_pattern('*.json'); $filter->set_name('Archivos JSON');
    $d->add_filter($filter);
    my $arch = undef;
    $arch = $d->get_filename() if $d->run() eq 'accept';
    $d->destroy(); return $arch;
}

# ---------------------------------------------------------------
# TAB: REPORTES
# ---------------------------------------------------------------
sub _tab_reportes {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_margin_start(15); $vbox->set_margin_end(15); $vbox->set_margin_top(15);

    my $lbl = Gtk3::Label->new('Generar reportes Graphviz (PNG):');
    $lbl->set_halign('start');
    $vbox->pack_start($lbl, 0,0,0);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(8);
    $vbox->pack_start($grid, 0,0,0);

    my @reportes = (
        ['Grafo de Colaboración',     sub { $self->_gen_reporte('grafo')     }],
        ['Lista de Adyacencia',       sub { $self->_gen_reporte('adj')       }],
        ['Tabla Hash',                sub { $self->_gen_reporte('hash')      }],
        ['Árbol de Merkle',           sub { $self->_gen_reporte('merkle')    }],
        ['Compresión LZW (chats)',    sub { $self->_gen_reporte('lzw')       }],
        ['Árbol AVL (Personal)',      sub { $self->_gen_reporte('avl')       }],
        ['Árbol BST (Equipos)',       sub { $self->_gen_reporte('bst')       }],
        ['Árbol B (Suministros)',     sub { $self->_gen_reporte('b')         }],
        ['Matriz Dispersa',           sub { $self->_gen_reporte('mat')       }],
        ['Medicamentos',              sub { $self->_gen_reporte('meds')      }],
    );

    for my $i (0..$#reportes) {
        my $btn = Gtk3::Button->new("📊 " . $reportes[$i][0]);
        $btn->signal_connect(clicked => $reportes[$i][1]);
        $grid->attach($btn, $i % 2, int($i/2), 1, 1);
    }

    $self->{reporte_imagen} = Gtk3::Image->new();
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic','automatic');
    $sw->add_with_viewport($self->{reporte_imagen});
    $vbox->pack_start($sw, 1, 1, 0);

    return $vbox;
}

sub _gen_reporte {
    my ($self, $tipo) = @_;
    my $estado = EstadoF3->get_instancia();
    my $dir    = $estado->dir_reportes();
    my $png;

    if    ($tipo eq 'grafo')  { $png = $estado->grafo->generar_dot("$dir/reporte_grafo.dot", $estado->usuarios) }
    elsif ($tipo eq 'adj')    { $png = $estado->grafo->generar_dot_adyacencia("$dir/reporte_adj.dot") }
    elsif ($tipo eq 'hash')   { $png = $estado->tabla_hash->generar_dot("$dir/reporte_hash.dot") }
    elsif ($tipo eq 'merkle') { $png = $estado->merkle->generar_dot("$dir/reporte_merkle.dot") }
    elsif ($tipo eq 'lzw')    { $png = LZW->generar_dot_archivos($estado->dir_chats(), "$dir/reporte_lzw.dot") }
    elsif ($tipo eq 'avl')    { $png = $estado->usuarios->generar_dot("$dir/reporte_avl.dot") }
    elsif ($tipo eq 'bst')    { $png = $estado->equipos->generar_dot("$dir/reporte_bst.dot") }
    elsif ($tipo eq 'b')      { $png = $estado->suministros->generar_dot("$dir/reporte_b.dot") }
    elsif ($tipo eq 'mat')    { $png = $estado->matriz->generar_dot("$dir/reporte_matriz.dot") }
    elsif ($tipo eq 'meds')   { $png = $estado->medicamentos->generar_dot("$dir/reporte_meds.dot") }

    if ($png && -e $png) {
        $self->{reporte_imagen}->set_from_file($png);
        $self->{reporte_imagen}->show();
    } else {
        $self->_msg("No se pudo generar el reporte. ¿Está instalado Graphviz?");
    }
}

1;
