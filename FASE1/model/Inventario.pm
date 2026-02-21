package Inventario;
use strict;
use warnings;
use NodoMedicamento;

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef,
        ultimo => undef,
    };
    bless $self, $class;
    return $self;
}

#insercion por codigo
sub insertar{
    my ($self, $me) = @_;
    my $nuevo= NodoMedicamento->new($me);

    #if si la lista esta vacia
    if(!$self->{primero}){
        $self->{primero} = $nuevo;
        $self->{ultimo} = $nuevo;
        return;

    }
     #se actualiza a actual el nodo ultimo (pasa al siguiente nodo)
    my $actual = $self->{primero};

    while($actual){
        if($me->get_codigo() lt $actual->get_dato()->get_codigo()){

            #insercion al inicio
            if(!$actual->get_anterior()){
            $nuevo->set_siguiente($actual);
            $actual->set_anterior($nuevo);
            $self->{primero} = $nuevo;
            }else{
            #insercion en medio
            my $anterior = $actual->get_anterior();
            $anterior->set_siguiente($nuevo);
            $nuevo->set_anterior($anterior);
            $nuevo->set_siguiente($actual);
            $actual->set_anterior($nuevo);
            }
            return;
    }
    $actual = $actual->get_siguiente();
    }

    #insercion al final
    $self->{ultimo}->set_siguiente($nuevo);
    $nuevo->set_anterior($self->{ultimo});
    $self->{ultimo} = $nuevo;

}
#listado (recorrido completo de la lista)
sub listar{
    my ($self) = @_;
    my $actual = $self->{primero};

    while($actual){
        my $m= $actual->get_dato();
        print "-------------------------\n";
        print "--------Inventario-------\n";
        print "Codigo: " . $m->get_codigo() . "\n";
        print "Nombre: " . $m->get_nombre() . "\n";
        print "Principio activo: " . $m->get_principioActivo() . "\n";
        print "Laboratorio: " . $m->get_laboratorio() . "\n";
        print "cantidad: " . $m->get_cantidad() . "\n";
        print "Fecha de vencimiento: " . $m->get_fechaVencimiento() . "\n";
        print "Precio: " . $m->get_precio() . "\n";
        print "Nivel minimo: " . $m->get_nivelMinimo() . "\n";

        if ($m->bajoStock()) {
            print "precaucion Bajo stock\n";
        }

        print "---------------------------\n";

        $actual = $actual->get_siguiente();

    }
}

#busqueda por codigo (recorrido de la lista hasta encontrar el medicamento con el codigo dado)
sub  buscar{
    my($self, $codigo) = @_;
    my $actual = $self->{primero};
    while($actual){
        if($actual->get_dato()->get_codigo() eq $codigo){
            return $actual->get_dato();
        }
        $actual = $actual->get_siguiente();
    }
    return undef; #no encontrado

}

sub buscar_por_nombre{
    my ($self, $nombre) = @_;
    my $actual = $self->{primero};

    while($actual){
        my $m= $actual->get_dato();
        if(lc($m->get_nombre()) eq lc($nombre)){
            return $m;
        }
        $actual = $actual->get_siguiente();
    }
    return undef; #no encontrado
}

#filtar por laboratorio
sub listar_por_laboratorio {
    my ($self, $laboratorio) = @_;
    my $actual = $self->{primero};
    my $encontrado = 0;

    print "\n--- INVENTARIO POR LABORATORIO: $laboratorio ---\n";

    while ($actual) {
        my $m = $actual->get_dato();
        if (lc($m->get_laboratorio()) eq lc($laboratorio)) {
            print "Codigo: ", $m->get_codigo(),
                  " | Nombre: ", $m->get_nombre(),
                  " | Precio: Q", $m->get_precio(),
                  " | Cantidad: ", $m->get_cantidad(), "\n";
            $encontrado = 1;
        }
        $actual = $actual->get_siguiente();
    }

    print "No hay medicamentos de ese laboratorio.\n" unless $encontrado;
}


1;