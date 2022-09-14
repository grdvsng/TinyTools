package TinyTools::Array::Int;
{
    use POSIX;
    use strict;
    use threads;
    use warnings;
    use feature 'say';
    use Exporter 'import';
    use TinyTools::Array::Utils;
    use MooseX::Params::Validate;

    our @EXPORT_OK = qw( binary_search index_of );

    sub binary_search {
        my ( $array, $value, $left, $right ) = @_;
        my $total = scalar(@$array) - 1;

        $right = $total if !$right || $right > $total;
        $left  = $total if $left > $total;

        my $low = $array->[$left];
        my $max = $array->[$right];

        return -1     if $right == -1;
        return $left  if $value == $low;
        return $right if $value == $max;
        return -1     if $right == $left && $low != $value;

        if ( $right >= $left ) {
            my $midle     = floor( $left + ( $right - $left ) / 2 );
            my $mid_value = $array->[$midle];

            if ( $value == $mid_value ) {
                return $midle;
            } elsif ( $mid_value > $value ) {
                return binary_search( $array, $value, $left, $midle - 1 );
            } else {
                return binary_search( $array, $value, $midle + 1, $right );
            }
        }

        return -1;
    }

    sub index_of {
        my ( $array, $value, $not_sorted, $ignore_threards ) = @_;

        return TinyTools::Array::Utils::index_of( $value, @$array )
            if $not_sorted;

        my $count = scalar(@$array);
        my $low = $array->[0];
        my $max = $array->[ $count - 1 ];

        return -1         if $count == 0;
        return 0          if $value == $low;
        return $count - 1 if $value == $max;

        if ( !$ignore_threards && $count >= 5_000_000 ) {
            my @array     = @$array;
            my $part_size = floor( ( $count / 100 ) * 10 );
            my $pushed    = 0;
            my @thrs      = ();

            while ( $pushed < $count ) {
                my $start = $pushed;
                my $end
                    = $pushed + $part_size < $count
                    ? $pushed + $part_size
                    : $count - 1;

                push(
                    @thrs,
                    threads->create(
                        sub {
                            index_of( [ @array[ $start .. $end ] ],
                                $value, 0, 1 );
                        }
                    )
                );

                $pushed += $part_size;
            }

            my $finded = -1;

            for ( my $i = 0; $i < scalar(@thrs); $i++ ) {
                my $thread = $thrs[$i];

                if ( $finded == -1 ) {
                    $finded = $thread->join;
                    $finded += $i * $part_size if $finded != -1;
                } else {
                    $thread->detach;
                }
            }

            return $finded;
        } else {
            my $current_value = $low;
            my $current_index = 1;
            my $last_index    = $current_index;

            while ( $value > $current_value && $current_index < $count ) {
                $last_index = $current_index;
                $current_index *= 2;
                $current_value = $array->[$current_index] || 0;
            }

            return binary_search( $array, $value, $last_index,
                $current_index < $count ? $current_index : $count - 1 );
        }
    }
};
1;
