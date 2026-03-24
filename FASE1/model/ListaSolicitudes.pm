package ListaSolicitudes;
use strict;
use warnings;

use NodoSolicitud;

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef,
        total => 0,
    };
    bless $self, $class;
    return $self;
}

sub agregar{
    my ($self, $solicitud)= @_;
    my $nuevoNodo = NodoSolicitud->new($solicitud);
    if(!$self->{primero}){
        $nuevoNodo->set_siguiente($nuevoNodo);
        $nuevoNodo->set_anterior($nuevoNodo);
        $self->{primero} = $nuevoNodo;
    }else{
        my $ultimo = $self->{primero}->get_anterior();#obtener el ultimo nodo de la lista
        $ultimo->set_siguiente($nuevoNodo);#actualizar el siguiente del ultimo nodo al nuevo nodo
        $nuevoNodo->set_anterior($ultimo);#actualizar el anterior del nuevo nodo al ultimo nodo
        $nuevoNodo->set_siguiente($self->{primero});#actualizar el siguiente del nuevo nodo al primer nodo
        $self->{primero}->set_anterior($nuevoNodo);#actualizar el anterior del primer nodo al nuevo nodo
    }
    $self->{total}++;#incrementar el total de solicitudes

}

sub obtener_primera{
    return $_[0]->{primero};
}

sub eliminar_primera{
    my ($self) = @_;
   return unless $self->{primero};
    if($self->{total}==1)
    {
        $self->{primero} = undef;
    }else{
        my $actual = $self->{primero};
        my $ant=$actual->get_anterior();
        my $sig=$actual->get_siguiente();
        $ant->set_siguiente($sig);
        $sig->set_anterior($ant);
        $self->{primero} = $sig;
    }
    $self->{total}--;
}

sub total{
    return $_[0]->{total};
}

1;