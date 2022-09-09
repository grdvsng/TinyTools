package TinyTools::DB::DBI;
{
    use Moose;
    use TinyTools::DB::DBI::Stream;

    extends 'DBI';

    sub pool {
        my $self = shift;
    }
};
1;
