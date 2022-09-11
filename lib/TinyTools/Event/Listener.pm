package TinyTools::Event::Listener;
{
    use Moose;
    use Types::Standard qw(Enum);

    has 'event'    => ( is => 'ro', isa => 'Str' );
    has 'sub_type' => ( is => 'ro', isa => Enum [qw( once regular )] );
    has 'handler'  => ( is => 'ro', isa => 'CodeRef' );
    has 'removed'  => ( is => 'rw', isa => 'Bool', default => 0 );

    sub is_once {
        return $_[0]->sub_type eq 'once';
    }

    sub is_regular {
        return $_[0]->sub_type eq 'regular';
    }
};
1;
