package TinyTools::DB::DBI::Stream;
{
    use Moose;
    use Data::Dumper;
    use MooseX::ClassAttribute;

    extends 'TinyTools::Event::Emiter';

    class_has 'supported_events' => (
        is      => 'rw',
        isa     => 'ArrayRef[Str]',
        default => sub { return [qw( error data end )]; },
    );
};
1;
