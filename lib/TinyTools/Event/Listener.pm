package TinyTools::Event::Listener;
{
    use Moose;
    use Moose::Util::TypeConstraints;
    use TinyTools::Array::Utils qw( index_of );

    my @LISTENER_TYPES = qw( once regular );

    subtype 'ListenerType' => as 'Type' =>
        where { index_of( $_, @LISTENER_TYPES ) != -1 }
    => message {'Incorrect listener type'};

    has 'event'    => ( is => 'ro', isa => 'Str' );
    has 'sub_type' => ( is => 'ro', isa => 'Type' );
    has 'handler'  => ( is => 'ro', isa => 'CodeRef' );
    has 'removed'  => ( is => 'rw', isa => 'Bool', default => 0 );

    sub is_once {
        return $_[0]->type eq 'once';
    }

    sub is_regular {
        return $_[0]->type eq 'regular';
    }
};
1;
