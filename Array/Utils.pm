package TinyTools::Array::Utils;
{
    use strict;
    use warnings;
    use Data::Dumper;
    use MooseX::Params::Validate;

    sub splice
    {
        my ( $index, $remove, $value, $array ) = pos_validated_list(
            \@_,
            { isa => 'Int'       },
            { isa => 'Int|Undef' },
            { isa => 'Any'       },
            { isa => 'Any'       },
        );

        my $length = scalar( @$array );
        my @new = ( );

        if ( $index < 0 )
        {
            $index = $index + $length + 1;
        }

        if ( $index >= $length - 1 )
        {
            if ( $remove > 0 )
            {
                $array->[ $length - 1 ] = $value;
            } elsif ( $index == $length - 1 ) {
                my $tmp = $array->[ $length - 1 ];

                $array->[ $index ] = $value;
                
                push( @$array, $tmp );
            } else {
                push( @$array, $value );
            }
        
            return $array;
        }

        if ( $index == 0 && !$remove )
        {
            unshift( @$array, $value );
        
            return $array;
        }

        my $i = -1;

        while ( my $elem = shift( @$array ) )
        {
            $i++;

            push( @new, $value ) if $i == $index;

            if ( $remove && $i >= $index )
            {
                $remove--;
            } else {
                push( @new, $elem );
            }
        }

       @$array = @new;

       return $array;
    }
};
1;