package VentanaUsuario;
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
    my $estado  = EstadoF3->get_instancia();
    my $usuario = $estado->get_usuario_actual();

    my $win = Gtk3::Window->new('toplevel');
    $self->{win} = $win;
    $win->set_title('EDD MedTrack F3 - Usuario');
    $win->set_default_size(900, 650);
    $win->set_position('center');
    $win->signal_connect(destroy => sub {
        # Guardar chats al cerrar
        if (defined $usuario) {
            $estado->guardar_chats_usuario($usuario->get_numero_colegio());
        }
        $estado->set_usuario_actual(undef);
        $self->{ventana_login}->show_all() if defined $self->{ventana_login};
    });

    my $vbox = Gtk3::Box->new('vertical', 0);
    $win->add($vbox);
    $vbox->pack_start($self->_crear_header($usuario), 0, 0, 0);

    my $nb = Gtk3::Notebook->new();
    $vbox->pack_start($nb, 1, 1, 0);

    my @permisos = @{ $usuario->get_permisos() };

    if (grep { $_ eq 'MEDICAMENTO' } @permisos) {
        $nb->append_page($self->_tab_medicamentos(), Gtk3::Label->new('💊 Medicamentos'));
    }
    if (grep { $_ eq 'EQUIPO' } @permisos) {
        $nb->append_page($self->_tab_equipos(), Gtk3::Label->new('🔧 Equipos'));
    }
    if (grep { $_ eq 'SUMINISTRO' } @permisos) {
        $nb->append_page($self->_tab_suministros(), Gtk3::Label->new('📦 Suministros'));
    }

    $nb->append_page($self->_tab_solicitudes(),   Gtk3::Label->new('📋 Solicitudes'));
    $nb->append_page($self->_tab_colaboracion(),  Gtk3::Label->new('🤝 Colaboración'));
    $nb->append_page($self->_tab_mensajeria(),    Gtk3::Label->new('💬 Mensajería'));
    $nb->append_page($self->_tab_perfil(),        Gtk3::Label->new('👤 Perfil'));

    $win->show_all();
}

sub _crear_header {
    my ($self, $usuario) = @_;
    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->override_background_color('normal', Gtk3::Gdk::RGBA::parse('#1a2744'));
    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span foreground="white" size="large" weight="bold"> EDD MEDTRACK F3 </span>');
    $titulo->set_margin_start(15); $titulo->set_margin_top(10); $titulo->set_margin_bottom(10);
    $hbox->pack_start($titulo, 0, 0, 0);
    my $nom  = $usuario->get_nombre_completo();
    my $dep  = $usuario->get_departamento();
    my $lbl  = Gtk3::Label->new('');
    $lbl->set_markup("<span foreground='#e67e22' size='small'> $nom | $dep </span>");
    $hbox->pack_end($lbl, 0, 0, 15);
    return $hbox;
}

sub _en_scrolled {
    my ($self, $w) = @_;
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic'); $sw->add($w); return $sw;
}

sub _crear_treeview {
    my ($self, @cols) = @_;
    my $store = Gtk3::ListStore->new(map { 'Glib::String' } @cols);
    my $tv    = Gtk3::TreeView->new($store);
    $tv->set_rules_hint(1);
    for my $i (0..$#cols) {
        my $r   = Gtk3::CellRendererText->new();
        my $col = Gtk3::TreeViewColumn->new_with_attributes($cols[$i], $r, text => $i);
        $col->set_resizable(1); $tv->append_column($col);
    }
    return ($tv, $store);
}

sub _msg {
    my ($self, $txt) = @_;
    my $d = Gtk3::MessageDialog->new($self->{win}, 'destroy-with-parent', 'info', 'ok', $txt);
    $d->run(); $d->destroy();
}

# ---------------------------------------------------------------
# TAB: MEDICAMENTOS (solo consulta)
# ---------------------------------------------------------------
sub _tab_medicamentos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);

    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    $self->{med_entry} = Gtk3::Entry->new();
    $self->{med_entry}->set_placeholder_text('Código o nombre...');
    $self->{med_entry}->set_size_request(200, -1);
    my $btn_cod = Gtk3::Button->new('🔍 Por código');
    my $btn_nom = Gtk3::Button->new('🔍 Por nombre');
    my $btn_ver = Gtk3::Button->new('📋 Ver todos');
    $hbox->pack_start(Gtk3::Label->new('Buscar:'), 0,0,0);
    $hbox->pack_start($self->{med_entry}, 0,0,0);
    $hbox->pack_start($btn_cod, 0,0,0);
    $hbox->pack_start($btn_nom, 0,0,0);
    $hbox->pack_end($btn_ver, 0,0,0);

    my ($tv, $store) = $self->_crear_treeview('Código','Nombre','Disponible','Vencimiento','Estado');
    $self->{med_res_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $self->{med_alerta} = Gtk3::Label->new('');
    $vbox->pack_start($self->{med_alerta}, 0, 0, 0);

    $btn_cod->signal_connect(clicked => sub {
        $self->_mostrar_medicamento(EstadoF3->get_instancia()->medicamentos->buscar($self->{med_entry}->get_text()));
    });
    $btn_nom->signal_connect(clicked => sub {
        $self->_mostrar_medicamento(EstadoF3->get_instancia()->medicamentos->buscar_por_nombre($self->{med_entry}->get_text()));
    });
    $btn_ver->signal_connect(clicked => sub { $self->_listar_todos_medicamentos() });
    return $vbox;
}

sub _mostrar_medicamento {
    my ($self, $m) = @_;
    $self->{med_res_store}->clear(); $self->{med_alerta}->set_text('');
    unless ($m) { $self->{med_alerta}->set_markup('<span foreground="#e74c3c">⚠ No encontrado.</span>'); return }
    my $iter = $self->{med_res_store}->append();
    $self->{med_res_store}->set($iter,
        0,$m->get_codigo(), 1,$m->get_nombre(), 2,$m->get_cantidad(),
        3,$m->get_fechaVencimiento(), 4,($m->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Normal'));
    $self->{med_alerta}->set_markup('<span foreground="#e67e22">⏳ Stock bajo mínimo</span>') if $m->bajo_stock();
}

sub _listar_todos_medicamentos {
    my ($self) = @_;
    $self->{med_res_store}->clear(); $self->{med_alerta}->set_text('');
    my $actual = EstadoF3->get_instancia()->medicamentos->{primero};
    my $alertas = 0;
    while ($actual) {
        my $m = $actual->get_dato();
        my $iter = $self->{med_res_store}->append();
        $self->{med_res_store}->set($iter,
            0,$m->get_codigo(), 1,$m->get_nombre(), 2,$m->get_cantidad(),
            3,$m->get_fechaVencimiento(), 4,($m->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Normal'));
        $alertas++ if $m->bajo_stock();
        $actual = $actual->get_siguiente();
    }
    $self->{med_alerta}->set_markup("<span foreground='#e74c3c'>⚠ $alertas con stock bajo</span>") if $alertas;
}

# ---------------------------------------------------------------
# TAB: EQUIPOS
# ---------------------------------------------------------------
sub _tab_equipos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    $self->{eq_entry} = Gtk3::Entry->new(); $self->{eq_entry}->set_placeholder_text('Código EQU...');
    my $btn_bus = Gtk3::Button->new('🔍 Buscar');
    my $btn_ver = Gtk3::Button->new('📋 Ver todos');
    $hbox->pack_start(Gtk3::Label->new('Código:'), 0,0,0);
    $hbox->pack_start($self->{eq_entry}, 0,0,0);
    $hbox->pack_start($btn_bus, 0,0,0); $hbox->pack_end($btn_ver, 0,0,0);
    my ($tv, $store) = $self->_crear_treeview('Código','Nombre','Fabricante','Precio','Disponible','Fecha','Estado');
    $self->{eq_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $self->{eq_alerta} = Gtk3::Label->new('');
    $vbox->pack_start($self->{eq_alerta}, 0, 0, 0);
    $btn_bus->signal_connect(clicked => sub {
        my $e = EstadoF3->get_instancia()->equipos->buscar($self->{eq_entry}->get_text());
        $self->_mostrar_equipo($e);
    });
    $btn_ver->signal_connect(clicked => sub { $self->_listar_todos_equipos() });
    return $vbox;
}

sub _mostrar_equipo {
    my ($self, $e) = @_;
    $self->{eq_store}->clear(); $self->{eq_alerta}->set_text('');
    unless ($e) { $self->{eq_alerta}->set_markup('<span foreground="#e74c3c">⚠ No encontrado.</span>'); return }
    my $iter = $self->{eq_store}->append();
    $self->{eq_store}->set($iter,
        0,$e->get_codigo(),1,$e->get_nombre(),2,$e->get_fabricante(),
        3,sprintf("Q%.2f",$e->get_precio()),4,$e->get_cantidad(),
        5,$e->get_fecha_ingreso(),6,($e->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible'));
    $self->{eq_alerta}->set_markup('<span foreground="#e74c3c">⚠ Stock bajo mínimo</span>') if $e->bajo_stock();
}

sub _listar_todos_equipos {
    my ($self) = @_;
    $self->{eq_store}->clear(); $self->{eq_alerta}->set_text('');
    my $alertas = 0;
    for my $e (EstadoF3->get_instancia()->equipos->inorden()) {
        my $iter = $self->{eq_store}->append();
        $self->{eq_store}->set($iter,
            0,$e->get_codigo(),1,$e->get_nombre(),2,$e->get_fabricante(),
            3,sprintf("Q%.2f",$e->get_precio()),4,$e->get_cantidad(),
            5,$e->get_fecha_ingreso(),6,($e->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible'));
        $alertas++ if $e->bajo_stock();
    }
    $self->{eq_alerta}->set_markup("<span foreground='#e74c3c'>⚠ $alertas con stock bajo</span>") if $alertas;
}

# ---------------------------------------------------------------
# TAB: SUMINISTROS
# ---------------------------------------------------------------
sub _tab_suministros {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);
    my $hbox = Gtk3::Box->new('horizontal', 6);
    $vbox->pack_start($hbox, 0, 0, 0);
    $self->{sum_entry} = Gtk3::Entry->new(); $self->{sum_entry}->set_placeholder_text('Código SUM...');
    my $btn_bus = Gtk3::Button->new('🔍 Buscar');
    my $btn_ver = Gtk3::Button->new('📋 Ver todos');
    $hbox->pack_start(Gtk3::Label->new('Código:'), 0,0,0);
    $hbox->pack_start($self->{sum_entry}, 0,0,0);
    $hbox->pack_start($btn_bus, 0,0,0); $hbox->pack_end($btn_ver, 0,0,0);
    my ($tv, $store) = $self->_crear_treeview('Código','Nombre','Fabricante','Precio','Disponible','Vencimiento','Estado');
    $self->{sum_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);
    $self->{sum_alerta} = Gtk3::Label->new('');
    $vbox->pack_start($self->{sum_alerta}, 0, 0, 0);
    $btn_bus->signal_connect(clicked => sub {
        my $s = EstadoF3->get_instancia()->suministros->buscar($self->{sum_entry}->get_text());
        $self->_mostrar_suministro($s);
    });
    $btn_ver->signal_connect(clicked => sub { $self->_listar_todos_suministros() });
    return $vbox;
}

sub _mostrar_suministro {
    my ($self, $s) = @_;
    $self->{sum_store}->clear(); $self->{sum_alerta}->set_text('');
    unless ($s) { $self->{sum_alerta}->set_markup('<span foreground="#e74c3c">⚠ No encontrado.</span>'); return }
    my $iter = $self->{sum_store}->append();
    $self->{sum_store}->set($iter,
        0,$s->get_codigo(),1,$s->get_nombre(),2,$s->get_fabricante(),
        3,sprintf("Q%.2f",$s->get_precio()),4,$s->get_cantidad(),
        5,$s->get_fecha_vencimiento(),6,($s->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible'));
    $self->{sum_alerta}->set_markup('<span foreground="#e74c3c">⚠ Stock bajo mínimo</span>') if $s->bajo_stock();
}

sub _listar_todos_suministros {
    my ($self) = @_;
    $self->{sum_store}->clear(); $self->{sum_alerta}->set_text('');
    my $alertas = 0;
    for my $s (EstadoF3->get_instancia()->suministros->inorden()) {
        my $iter = $self->{sum_store}->append();
        $self->{sum_store}->set($iter,
            0,$s->get_codigo(),1,$s->get_nombre(),2,$s->get_fabricante(),
            3,sprintf("Q%.2f",$s->get_precio()),4,$s->get_cantidad(),
            5,$s->get_fecha_vencimiento(),6,($s->bajo_stock() ? '⚠ BAJO STOCK' : '✓ Disponible'));
        $alertas++ if $s->bajo_stock();
    }
    $self->{sum_alerta}->set_markup("<span foreground='#e74c3c'>⚠ $alertas con stock bajo</span>") if $alertas;
}

# ---------------------------------------------------------------
# TAB: SOLICITUDES DE REABASTECIMIENTO
# ---------------------------------------------------------------
sub _tab_solicitudes {
    my ($self) = @_;
    my $usuario = EstadoF3->get_instancia()->get_usuario_actual();
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);

    my $lbl = Gtk3::Label->new('');
    $lbl->set_markup('<b>Nueva Solicitud de Reabastecimiento:</b>');
    $lbl->set_halign('start');
    $vbox->pack_start($lbl, 0, 0, 4);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(8); $grid->set_row_spacing(6);
    $grid->set_margin_start(10);
    $vbox->pack_start($grid, 0, 0, 0);

    # Tipo de insumo
    $grid->attach(Gtk3::Label->new('Tipo de insumo:'), 0, 0, 1, 1);
    $self->{sol_tipo} = Gtk3::ComboBoxText->new();
    my @permisos = @{ $usuario->get_permisos() };
    $self->{sol_tipo}->append_text('MEDICAMENTO') if grep { $_ eq 'MEDICAMENTO' } @permisos;
    $self->{sol_tipo}->append_text('EQUIPO')      if grep { $_ eq 'EQUIPO'      } @permisos;
    $self->{sol_tipo}->append_text('SUMINISTRO')  if grep { $_ eq 'SUMINISTRO'  } @permisos;
    $self->{sol_tipo}->set_active(0);
    $grid->attach($self->{sol_tipo}, 1, 0, 1, 1);

    $grid->attach(Gtk3::Label->new('Código del ítem:'), 0, 1, 1, 1);
    $self->{sol_cod} = Gtk3::Entry->new(); $self->{sol_cod}->set_placeholder_text('MED-001 / EQU-001...');
    $grid->attach($self->{sol_cod}, 1, 1, 1, 1);

    $grid->attach(Gtk3::Label->new('Nombre:'), 0, 2, 1, 1);
    $self->{sol_nom} = Gtk3::Entry->new();
    $grid->attach($self->{sol_nom}, 1, 2, 1, 1);

    $grid->attach(Gtk3::Label->new('Cantidad requerida:'), 0, 3, 1, 1);
    $self->{sol_cant} = Gtk3::Entry->new(); $self->{sol_cant}->set_placeholder_text('0');
    $grid->attach($self->{sol_cant}, 1, 3, 1, 1);

    $grid->attach(Gtk3::Label->new('Motivo clínico:'), 0, 4, 1, 1);
    $self->{sol_motivo} = Gtk3::Entry->new();
    $self->{sol_motivo}->set_size_request(300, -1);
    $grid->attach($self->{sol_motivo}, 1, 4, 1, 1);

    my $btn_enviar = Gtk3::Button->new('📤 Enviar Solicitud');
    $btn_enviar->set_halign('start');
    $vbox->pack_start($btn_enviar, 0, 0, 6);

    # Historial
    my $lbl2 = Gtk3::Label->new('');
    $lbl2->set_markup('<b>Historial de solicitudes del departamento:</b>');
    $lbl2->set_halign('start');
    $vbox->pack_start($lbl2, 0, 0, 2);

    my ($tv, $store) = $self->_crear_treeview('ID','Tipo','Código','Nombre','Cantidad','Fecha','Estado');
    $self->{hist_store} = $store;
    $vbox->pack_start($self->_en_scrolled($tv), 1, 1, 0);

    $btn_enviar->signal_connect(clicked => sub {
        my $tipo  = $self->{sol_tipo}->get_active_text() // '';
        my $cod   = $self->{sol_cod}->get_text();
        my $nom   = $self->{sol_nom}->get_text();
        my $cant  = $self->{sol_cant}->get_text() || 0;
        my $motiv = $self->{sol_motivo}->get_text();

        unless ($tipo && $cod && $cant > 0) {
            $self->_msg("Por favor completa tipo, código y cantidad."); return;
        }

        require Solicitud;
        my $sol = Solicitud->new({
            departamento    => $usuario->get_departamento(),
            tipo_item       => $tipo,
            codigo          => $cod,
            nombre          => $nom,
            cantidad        => int($cant),
            motivo          => $motiv,
            solicitante_col => $usuario->get_numero_colegio(),
        });
        EstadoF3->get_instancia()->agregar_solicitud($sol);
        $self->_msg("Solicitud enviada: " . $sol->get_id());
        $self->_refrescar_historial();
        $self->{sol_cod}->set_text('');
        $self->{sol_nom}->set_text('');
        $self->{sol_cant}->set_text('');
        $self->{sol_motivo}->set_text('');
    });

    $self->_refrescar_historial();
    return $vbox;
}

sub _refrescar_historial {
    my ($self) = @_;
    return unless defined $self->{hist_store};
    my $usuario = EstadoF3->get_instancia()->get_usuario_actual();
    $self->{hist_store}->clear();
    my $dep = $usuario->get_departamento();
    for my $s (EstadoF3->get_instancia()->solicitudes->por_departamento($dep)) {
        my $iter = $self->{hist_store}->append();
        $self->{hist_store}->set($iter,
            0,$s->get_id(),      1,$s->get_tipo_item(), 2,$s->get_codigo(),
            3,$s->get_nombre(),  4,$s->get_cantidad(),  5,$s->get_timestamp(),
            6,$s->get_estado());
    }
}

# ---------------------------------------------------------------
# TAB: RED DE COLABORACION (usuario)
# ---------------------------------------------------------------
sub _tab_colaboracion {
    my ($self) = @_;
    my $usuario = EstadoF3->get_instancia()->get_usuario_actual();
    my $mi_col  = $usuario->get_numero_colegio();

    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_margin_start(10); $vbox->set_margin_top(10);

    my $nb = Gtk3::Notebook->new();
    $vbox->pack_start($nb, 1, 1, 0);

    # --- Sub-tab: Colaboradores actuales ---
    my $vb1 = Gtk3::Box->new('vertical', 6);
    $vb1->set_margin_start(8); $vb1->set_margin_top(8);
    my $btn_ref1 = Gtk3::Button->new('↻ Refrescar');
    $btn_ref1->set_halign('start');
    $vb1->pack_start($btn_ref1, 0, 0, 0);
    my ($tv1, $store1) = $self->_crear_treeview('Núm. Colegio','Nombre','Departamento','Especialidad');
    $self->{colab_store} = $store1;
    $vb1->pack_start($self->_en_scrolled($tv1), 1, 1, 0);
    $btn_ref1->signal_connect(clicked => sub { $self->_refrescar_colaboradores($mi_col) });
    $self->_refrescar_colaboradores($mi_col);
    $nb->append_page($vb1, Gtk3::Label->new('Colaboradores'));

    # --- Sub-tab: Sugerencias BFS ---
    my $vb2 = Gtk3::Box->new('vertical', 6);
    $vb2->set_margin_start(8); $vb2->set_margin_top(8);
    my $btn_sug = Gtk3::Button->new('🔍 Calcular sugerencias');
    $btn_sug->set_halign('start');
    $vb2->pack_start($btn_sug, 0, 0, 0);
    my ($tv2, $store2) = $self->_crear_treeview('Núm. Colegio','Nombre','Depto','Colaboradores en común');
    $self->{sug_store} = $store2;
    $vb2->pack_start($self->_en_scrolled($tv2), 1, 1, 0);
    $btn_sug->signal_connect(clicked => sub {
        $self->{sug_store}->clear();
        my $avl = EstadoF3->get_instancia()->usuarios;
        for my $sug (EstadoF3->get_instancia()->grafo->sugerencias($mi_col)) {
            my $u = $avl->buscar($sug->{col});
            my $iter = $self->{sug_store}->append();
            $self->{sug_store}->set($iter,
                0, $sug->{col},
                1, $u ? $u->get_nombre_completo() : '?',
                2, $u ? ($u->get_departamento() // 'N/A') : 'N/A',
                3, $sug->{comunes},
            );
        }
    });
    $nb->append_page($vb2, Gtk3::Label->new('Sugerencias'));

    # --- Sub-tab: Enviar solicitud ---
    my $vb3 = Gtk3::Box->new('vertical', 8);
    $vb3->set_margin_start(8); $vb3->set_margin_top(8);
    my $hb3 = Gtk3::Box->new('horizontal', 6);
    $vb3->pack_start($hb3, 0, 0, 0);
    my $entry_sol = Gtk3::Entry->new(); $entry_sol->set_placeholder_text('Núm. colegio del receptor...');
    my $btn_sol   = Gtk3::Button->new('📨 Enviar solicitud de colaboración');
    $hb3->pack_start(Gtk3::Label->new('Receptor:'), 0,0,0);
    $hb3->pack_start($entry_sol, 0,0,0);
    $hb3->pack_start($btn_sol,   0,0,0);
    $self->{sol_colab_msg} = Gtk3::Label->new('');
    $vb3->pack_start($self->{sol_colab_msg}, 0, 0, 0);
    $btn_sol->signal_connect(clicked => sub {
        my $rec = $entry_sol->get_text(); return unless $rec;
        if ($rec eq $mi_col) {
            $self->{sol_colab_msg}->set_markup('<span foreground="#e74c3c">No puedes enviarte una solicitud a ti mismo.</span>'); return;
        }
        my $grafo = EstadoF3->get_instancia()->grafo;
        if ($grafo->son_colaboradores($mi_col, $rec)) {
            $self->{sol_colab_msg}->set_markup('<span foreground="#e67e22">Ya son colaboradores.</span>'); return;
        }
        $grafo->agregar_nodo($mi_col);
        $grafo->agregar_nodo($rec);
        $grafo->agregar_solicitud($mi_col, $rec);
        $self->{sol_colab_msg}->set_markup('<span foreground="#2ecc71">✓ Solicitud enviada — pendiente de aceptación.</span>');
        $entry_sol->set_text('');
    });
    $nb->append_page($vb3, Gtk3::Label->new('Enviar solicitud'));

    # --- Sub-tab: Gestionar solicitudes recibidas ---
    my $vb4 = Gtk3::Box->new('vertical', 6);
    $vb4->set_margin_start(8); $vb4->set_margin_top(8);
    my $btn_ref4 = Gtk3::Button->new('↻ Refrescar');
    $btn_ref4->set_halign('start');
    $vb4->pack_start($btn_ref4, 0, 0, 0);
    my ($tv4, $store4) = $self->_crear_treeview('Solicitante','Nombre','Estado');
    $self->{recv_store} = $store4;
    $self->{recv_tv}    = $tv4;
    $vb4->pack_start($self->_en_scrolled($tv4), 1, 1, 0);

    my $hb4 = Gtk3::Box->new('horizontal', 6);
    $vb4->pack_start($hb4, 0, 0, 0);
    my $btn_acp = Gtk3::Button->new('✓ Aceptar seleccionada');
    my $btn_rec = Gtk3::Button->new('✕ Rechazar seleccionada');
    $hb4->pack_start($btn_acp, 0,0,0);
    $hb4->pack_start($btn_rec, 0,0,0);

    $btn_ref4->signal_connect(clicked => sub { $self->_refrescar_solicitudes_recibidas($mi_col) });

    $btn_acp->signal_connect(clicked => sub {
        my ($model, $iter) = $self->{recv_tv}->get_selection->get_selected();
        return unless defined $iter;
        my $sol_col = $model->get($iter, 0);
        EstadoF3->get_instancia()->grafo->aceptar_solicitud($sol_col, $mi_col);
        $self->_refrescar_solicitudes_recibidas($mi_col);
        $self->_refrescar_colaboradores($mi_col);
    });
    $btn_rec->signal_connect(clicked => sub {
        my ($model, $iter) = $self->{recv_tv}->get_selection->get_selected();
        return unless defined $iter;
        my $sol_col = $model->get($iter, 0);
        EstadoF3->get_instancia()->grafo->rechazar_solicitud($sol_col, $mi_col);
        $self->_refrescar_solicitudes_recibidas($mi_col);
    });

    $self->_refrescar_solicitudes_recibidas($mi_col);
    $nb->append_page($vb4, Gtk3::Label->new('Recibidas'));

    return $vbox;
}

sub _refrescar_colaboradores {
    my ($self, $mi_col) = @_;
    return unless defined $self->{colab_store};
    $self->{colab_store}->clear();
    my $avl = EstadoF3->get_instancia()->usuarios;
    for my $col (EstadoF3->get_instancia()->grafo->vecinos($mi_col)) {
        my $u = $avl->buscar($col);
        my $iter = $self->{colab_store}->append();
        $self->{colab_store}->set($iter,
            0, $col,
            1, $u ? $u->get_nombre_completo() : '(desconocido)',
            2, $u ? ($u->get_departamento() // 'N/A') : 'N/A',
            3, $u ? ($u->get_especialidad() || 'N/A') : 'N/A',
        );
    }
}

sub _refrescar_solicitudes_recibidas {
    my ($self, $mi_col) = @_;
    return unless defined $self->{recv_store};
    $self->{recv_store}->clear();
    my $avl = EstadoF3->get_instancia()->usuarios;
    for my $s (EstadoF3->get_instancia()->grafo->solicitudes_recibidas($mi_col)) {
        my $u = $avl->buscar($s->{solicitante});
        my $iter = $self->{recv_store}->append();
        $self->{recv_store}->set($iter,
            0, $s->{solicitante},
            1, $u ? $u->get_nombre_completo() : '?',
            2, $s->{estado},
        );
    }
}

# ---------------------------------------------------------------
# TAB: MENSAJERIA INTERNA (LZW)
# ---------------------------------------------------------------
sub _tab_mensajeria {
    my ($self) = @_;
    my $usuario = EstadoF3->get_instancia()->get_usuario_actual();
    my $mi_col  = $usuario->get_numero_colegio();

    my $hbox_main = Gtk3::Box->new('horizontal', 0);
    $hbox_main->set_margin_start(6); $hbox_main->set_margin_top(6);

    # Panel izquierdo: lista de conversaciones
    my $vb_izq = Gtk3::Box->new('vertical', 6);
    $vb_izq->set_size_request(200, -1);
    $hbox_main->pack_start($vb_izq, 0, 0, 0);

    my $lbl_conv = Gtk3::Label->new('');
    $lbl_conv->set_markup('<b>Conversaciones:</b>');
    $lbl_conv->set_halign('start');
    $vb_izq->pack_start($lbl_conv, 0, 0, 0);

    my ($tv_conv, $store_conv) = $self->_crear_treeview('Colaborador');
    $self->{conv_store} = $store_conv;
    $self->{conv_tv}    = $tv_conv;
    $vb_izq->pack_start($self->_en_scrolled($tv_conv), 1, 1, 0);

    my $btn_ref_conv = Gtk3::Button->new('↻ Actualizar');
    $vb_izq->pack_start($btn_ref_conv, 0, 0, 0);

    # Separador
    $hbox_main->pack_start(Gtk3::Separator->new('vertical'), 0, 0, 4);

    # Panel derecho: chat
    my $vb_der = Gtk3::Box->new('vertical', 6);
    $hbox_main->pack_start($vb_der, 1, 1, 0);

    $self->{chat_receptor} = Gtk3::Label->new('');
    $self->{chat_receptor}->set_markup('<i>Selecciona un colaborador</i>');
    $self->{chat_receptor}->set_halign('start');
    $vb_der->pack_start($self->{chat_receptor}, 0, 0, 0);

    # Área de mensajes
    my $tv_msg = Gtk3::TextView->new();
    $tv_msg->set_editable(0);
    $tv_msg->set_wrap_mode('word');
    $self->{chat_buf} = $tv_msg->get_buffer();
    my $sw_msg = Gtk3::ScrolledWindow->new();
    $sw_msg->set_policy('automatic', 'automatic');
    $sw_msg->add($tv_msg);
    $vb_der->pack_start($sw_msg, 1, 1, 0);

    # Entrada de mensaje
    my $hb_input = Gtk3::Box->new('horizontal', 6);
    $vb_der->pack_start($hb_input, 0, 0, 0);
    $self->{msg_entry} = Gtk3::Entry->new();
    $self->{msg_entry}->set_placeholder_text('Escribe un mensaje...');
    $self->{msg_entry}->set_hexpand(1);
    my $btn_send = Gtk3::Button->new('Enviar ➤');
    $hb_input->pack_start($self->{msg_entry}, 1,1,0);
    $hb_input->pack_start($btn_send, 0,0,0);

    $self->{chat_receptor_col} = undef;

    # Al seleccionar conversación
    $tv_conv->get_selection->signal_connect(changed => sub {
        my ($model, $iter) = $tv_conv->get_selection->get_selected();
        return unless defined $iter;
        my $receptor_col = $model->get($iter, 0);
        $self->{chat_receptor_col} = $receptor_col;
        my $avl = EstadoF3->get_instancia()->usuarios;
        my $u   = $avl->buscar($receptor_col);
        my $nom = $u ? $u->get_nombre_completo() : $receptor_col;
        $self->{chat_receptor}->set_markup("<b>Chat con:</b> $nom ($receptor_col)");
        $self->_cargar_chat($mi_col, $receptor_col);
    });

    $btn_send->signal_connect(clicked => sub { $self->_enviar_mensaje($mi_col) });
    $self->{msg_entry}->signal_connect(activate => sub { $self->_enviar_mensaje($mi_col) });

    $btn_ref_conv->signal_connect(clicked => sub { $self->_refrescar_conversaciones($mi_col) });
    $self->_refrescar_conversaciones($mi_col);

    return $hbox_main;
}

sub _refrescar_conversaciones {
    my ($self, $mi_col) = @_;
    return unless defined $self->{conv_store};
    $self->{conv_store}->clear();
    # Conversaciones = colaboradores directos en el grafo
    for my $col (sort EstadoF3->get_instancia()->grafo->vecinos($mi_col)) {
        my $iter = $self->{conv_store}->append();
        $self->{conv_store}->set($iter, 0, $col);
    }
}

sub _cargar_chat {
    my ($self, $mi_col, $receptor_col) = @_;
    my $clave = EstadoF3->get_instancia()->clave_chat($mi_col, $receptor_col);
    my $msgs  = EstadoF3->get_instancia()->chats->{$clave} // [];
    my $texto = '';
    for my $m (@$msgs) {
        my $quien = $m->{remitente} eq $mi_col ? 'Tú' : $m->{remitente};
        $texto .= "[$m->{timestamp}] $quien: $m->{contenido}\n";
    }
    $self->{chat_buf}->set_text($texto || '(Sin mensajes aún)');
    # Scroll al final
    my $end = $self->{chat_buf}->get_end_iter();
    $self->{chat_buf}->place_cursor($end);
}

sub _enviar_mensaje {
    my ($self, $mi_col) = @_;
    my $receptor = $self->{chat_receptor_col};
    unless (defined $receptor) { $self->_msg("Selecciona un colaborador primero."); return }

    my $contenido = $self->{msg_entry}->get_text();
    return unless length($contenido) > 0;

    # Verificar que sean colaboradores
    unless (EstadoF3->get_instancia()->grafo->son_colaboradores($mi_col, $receptor)) {
        $self->_msg("Solo puedes chatear con colaboradores directos."); return;
    }

    EstadoF3->get_instancia()->agregar_mensaje($mi_col, $receptor, $contenido);
    $self->{msg_entry}->set_text('');
    $self->_cargar_chat($mi_col, $receptor);
}

# ---------------------------------------------------------------
# TAB: PERFIL
# ---------------------------------------------------------------
sub _tab_perfil {
    my ($self) = @_;
    my $estado  = EstadoF3->get_instancia();
    my $usuario = $estado->get_usuario_actual();

    my $vbox = Gtk3::Box->new('vertical', 12);
    $vbox->set_margin_start(30); $vbox->set_margin_top(20);

    my $titulo = Gtk3::Label->new('');
    $titulo->set_markup('<span size="large" weight="bold">Mi Perfil</span>');
    $titulo->set_halign('start');
    $vbox->pack_start($titulo, 0, 0, 0);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(16); $grid->set_row_spacing(8);
    $vbox->pack_start($grid, 0, 0, 0);

    my @info = (
        ['Número de colegio:', $usuario->get_numero_colegio()],
        ['Tipo de usuario:',   $usuario->get_tipo_usuario()],
        ['Departamento:',      $usuario->get_departamento() // 'SIN-DEP'],
        ['Especialidad:',      $usuario->get_especialidad() || 'N/A'],
        ['Acceso a:',          join(', ', @{ $usuario->get_permisos() }) || 'Sin acceso'],
    );
    for my $i (0..$#info) {
        my $lk = Gtk3::Label->new(''); $lk->set_markup("<b>$info[$i][0]</b>"); $lk->set_halign('start');
        $grid->attach($lk, 0, $i, 1, 1);
        my $lv = Gtk3::Label->new($info[$i][1]); $lv->set_halign('start');
        $grid->attach($lv, 1, $i, 1, 1);
    }

    $vbox->pack_start(Gtk3::Separator->new('horizontal'), 0, 0, 4);

    my $lbl_e = Gtk3::Label->new(''); $lbl_e->set_markup('<b>Editar:</b>'); $lbl_e->set_halign('start');
    $vbox->pack_start($lbl_e, 0, 0, 0);

    my $grid2 = Gtk3::Grid->new(); $grid2->set_column_spacing(12); $grid2->set_row_spacing(8);
    $vbox->pack_start($grid2, 0, 0, 0);

    $grid2->attach(Gtk3::Label->new('Nombre completo:'), 0, 0, 1, 1);
    $self->{perfil_nom} = Gtk3::Entry->new();
    $self->{perfil_nom}->set_text($usuario->get_nombre_completo());
    $self->{perfil_nom}->set_size_request(280, -1);
    $grid2->attach($self->{perfil_nom}, 1, 0, 1, 1);

    $grid2->attach(Gtk3::Label->new('Nueva contraseña:'), 0, 1, 1, 1);
    $self->{perfil_pass} = Gtk3::Entry->new();
    $self->{perfil_pass}->set_visibility(0);
    $self->{perfil_pass}->set_placeholder_text('Dejar vacío para no cambiar');
    $self->{perfil_pass}->set_size_request(280, -1);
    $grid2->attach($self->{perfil_pass}, 1, 1, 1, 1);

    $self->{perfil_msg} = Gtk3::Label->new('');
    $vbox->pack_start($self->{perfil_msg}, 0, 0, 0);

    my $btn = Gtk3::Button->new('💾 Guardar cambios');
    $btn->set_halign('start');
    $btn->signal_connect(clicked => sub {
        my $nom  = $self->{perfil_nom}->get_text();
        my $pass = $self->{perfil_pass}->get_text();
        $usuario->set_nombre_completo($nom) if $nom;
        if ($pass) { $usuario->set_contrasena($pass); $self->{perfil_pass}->set_text('') }
        $self->{perfil_msg}->set_markup('<span foreground="#2ecc71">✓ Perfil actualizado</span>');
    });
    $vbox->pack_start($btn, 0, 0, 0);

    return $vbox;
}

1;
