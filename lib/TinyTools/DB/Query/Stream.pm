package TinyTools::DB::Query::Stream;
{
    use strict;
    use warnings;
    use TinyTools::DB::Query::Stream::Insert;
    use TinyTools::DB::Query::Stream::Select;

    sub insert {
        my $cls = shift;

        return TinyTools::DB::Query::Stream::Insert->new(@_);
    }

    sub select {
        my $cls = shift;

        return TinyTools::DB::Query::Stream::Select->new(@_);
    }
};
1;
