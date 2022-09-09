package TinyTools::Hash::Set;
{
    use Moose;

    use Carp;
    use Digest::MD5;
    use Data::Dumper;
    use Storable qw(dclone);
    use TinyTools::Array::Utils;
    use feature                qw( signatures );
    use TinyTools::Digest::MD5 qw( md5sum );

    use overload
        '""'  => \&to_string,
        '+'   => \&merge,
        '@{}' => sub { @{ $_[0]->to_array } };

    has 'current_position' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        reader  => '_get_current_position',
        writer  => '_set_current_position'
    );

    has 'is_empty' => (
        is      => 'rw',
        isa     => 'Bool',
        default => 1,
        writer  => '_set_is_empty'
    );

    has 'length' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        writer  => '_set_length',
    );

    has 'store' => (
        is      => 'rw',
        isa     => 'HashRef',
        default => sub { {} },
        reader  => '_get_store',
        writer  => '_set_store',
        trigger => sub {
            my ( $self, $store ) = @_;
            my $len = scalar( keys(%$store) );
            my $pos = $self->_get_current_position + 1;

            $self->_set_current_position($pos);
            $self->_set_is_empty( !$len );
            $self->_set_length($len);
        }
    );

    sub _contains ( $self, $key ) {
        my $store = $self->_get_store;

        return exists $store->{$key};
    }

    sub contains ( $self, $value ) {
        my $key = ref $value ? md5sum($value) : $value;

        return $self->_contains($key);
    }

    sub clear ($self) {
        $self->_set_store( {} );
    }

    sub insert ( $self, $value, $then = undef ) {
        my $key = ref $value ? md5sum($value) : $value;

        if ( !$self->_contains($key) ) {
            $then->($value) if $then;

            my $store = $self->_get_store;

            $store->{$key} = {
                position => $self->_get_current_position,
                value    => ref $value ? dclone($value) : $value,
            };

            $self->_set_store($store);
        }
    }

    sub replace ( $self, $value, $newValue ) {
        my $store  = $self->_get_store;
        my $oldKey = ref $value    ? md5sum($value)    : $value;
        my $key    = ref $newValue ? md5sum($newValue) : $newValue;

        if ( !$self->_contains($oldKey) ) {
            confess Dumper($value) . " not exists!";
        } else {
            my $oldValue = delete $store->{$oldKey};

            $store->{$key} = {
                position => $oldValue->{position},
                value    => ref $newValue ? dclone($newValue) : $newValue,
            };
        }

        $self->_set_store($store);
    }

    sub remove ( $self, $value ) {
        my $store = $self->_get_store;
        my $key   = ref $value ? md5sum($value) : $value;

        if ( $self->_contains($key) ) {
            my $item = delete $store->{$key};

            $self->_set_store($store);

            return $item->{value};
        }

        return undef;
    }

    sub to_array ($self) {
        my $store   = $self->_get_store;
        my @data    = values(%$store);
        my @result  = ();
        my @temp    = ();
        my $started = 0;

        while ( my $item = pop(@data) ) {
            my $pushed = 0;
            my @store  = ();

            for ( my $i = 0; $i < scalar(@temp); $i++ ) {
                my $position = $temp[$i];

                if ( $position > $item->{position} ) {
                    TinyTools::Array::Utils::splice( $i, 0,
                        $item->{position}, \@temp );
                    TinyTools::Array::Utils::splice( $i, 0,
                        $item->{value}, \@result );

                    $pushed = 1;
                    last;
                }
            }

            if ( !$pushed ) {
                push( @result, $item->{value} );
                push( @temp,   $item->{position} );
            }
        }

        return \@result;
    }

    sub to_string ($self) {
        my $terse = $Data::Dumper::Terse;

        $Data::Dumper::Terse = 1;

        my $text = Dumper( $self->toArray );

        $Data::Dumper::Terse = $terse;

        return $text;
    }
};
1;
