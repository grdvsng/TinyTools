package TinyTools::DB::Query::Stream::Select;
{
    use Moose;
    use Data::Dumper;
    use SQL::Abstract;
    use feature 'say';
    use Carp 'confess';
    use IO::Async::Function;
    use SQL::Abstract::Limit;
    use MooseX::ClassAttribute;
    use IO::Async::Timer::Periodic;

    extends 'TinyTools::DB::Query::Stream::Insert';

    class_has 'supported_events' => (
        is      => 'rw',
        isa     => 'ArrayRef[Str]',
        default => sub { return [qw( error data end )]; },
    );

    has "function" => (
        is      => 'ro',
        isa     => 'IO::Async::Function',
        lazy    => 1,
        default => sub {
            my $self     = shift;
            my $function = IO::Async::Function->new(
                code => sub {
                    my ( $limit, $offset ) = @_;
                    my $dbh = $self->dbh->();
                    my $sql = SQL::Abstract::Limit->new(
                        limit_dialect => $dbh );

                    my ( $stmt, @bind )
                        = $sql->select( $self->table, $self->fields || '*',
                        $self->where, $self->order, $limit, $offset );

                    my $sth = $dbh->prepare($stmt);

                    eval { $sth->execute(@bind) };

                    confess $@ if $@;

                    my $rows = eval { $sth->fetchall_arrayref( {} ) };

                    confess $@ if $@;

                    $dbh->disconnect;

                    return $rows;
                }
            );

            $self->loop->add($function);

            $function->start;

            return $function;
        }
    );

    has "cursor" => ( is => 'rw', isa => 'Int', default => 0 );
    has 'fields' => ( is => 'rw', isa => 'ArrayRef[Str]' );
    has 'where'  => ( is => 'rw', isa => 'HashRef' );
    has 'order'  => ( is => 'rw', isa => 'HashRef' );

    sub _write {
        my $self   = shift;
        my $offset = $self->cursor;
        my $limit  = $self->max_store_size;

        $self->cursor( $limit + $offset );

        eval {
            $self->function->call( args => [ $limit, $offset ] )->on_fail(
                sub {
                    my $error = shift;

                    $self->emit( 'error', $error );
                }
            )->on_done(
                sub {
                    my $rows = shift;

                    if ( scalar(@$rows) == 0 ) {
                        $self->end;
                    } else {
                        $self->emit( 'data', $_ ) for @$rows;
                    }
                }
            )->get;
        };

        $self->emit( 'error', $@ ) if $@;
    }

    sub end {
        my $self = shift;

        $self->timer->stop;
        $self->function->stop;

        $self->emit( 'end', $self );
    }
};
1;
