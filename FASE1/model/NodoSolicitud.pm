package NodoSolicitud;
use strict;
use warnings;

sub new{
    my($class, $solicitud) = @_;

    my $self = {
       dato => $solicitud, #indice para la solicitud
       anterior => undef,
         siguiente => undef,
    };
    bless $self, $class;
    return $self;


}

#ggetters

sub get_dato {
    $_[0]->{dato}}
sub get_anterior {
    $_[0]->{anterior}}
sub get_siguiente {
    $_[0]->{siguiente}}

#setters
sub set_anterior{
    $_[0]->{anterior} = $_[1];}
sub set_siguiente{
    $_[0]->{siguiente} = $_[1];}

1;
