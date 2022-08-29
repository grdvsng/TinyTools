package TinyTools::Hash::Set;
{
    use strict;
    use warnings;

    use Carp;
    use Data::Dumper;
    use feature qw( signatures );

    use overload
        '""' => \&toString;

    sub new( $cls )
    {
        return bless( {
            _store => { },
            _current_position => 0,
            _length => 0,
        }, $cls );
    }

    sub contains( $self, $value )
    {
        my $store = $self->{_store};

        return exists $store->{$value};
    }

    sub clear( $self )
    {
        $self->{_store} = {};
        $self->{_length} = 0;
    }

    sub insert( $self, $value )
    {
        my $store = $self->{_store};

        if ( !$self->contains($value) )
        {
            $store->{$value} = $self->{_current_position};
            $self->{_current_position} += 1;
            $self->{_length} += 1;
        }
    }

    sub replace( $self, $value, $newValue )
    {
        my $store = $self->{_store};

        if ( !$self->contains($value) )
        {
            confess Dumper($value)." not exists!";
        } else {
            my $position = delete $store->{$value};

            $store->{$newValue} = $position;
        }
    }

    sub isEmpty( $self )
    {
        my $store = $self->{_store};

        return $self->length == 0;
    }

    sub length( $self )
    {
        return $self->{_length};
    }

    sub remove( $self, $value )
    {
        my $store = $self->{_store};

        if ( $self->contains($value) )
        {
            my $position = delete $store->{$value};
            
            $self->{_length} -= 1;

            return $value;
        }

        return undef;
    }

    sub toArray( $self )
    {
        my $store = $self->{_store};
        my @data  = sort( { $store->{$a} > $store->{$b} } keys( %$store ) );

        return \@data;
    }

    sub toString( $self )
    {
        $Data::Dumper::Terse = 1;

        return Dumper( $self->toArray );
    }

    sub DESTROY( $self )
    {
        $self->{_store} = undef;
        $self->{_current_position} = undef;
        $self->{_length} = undef;
    }
};
1;