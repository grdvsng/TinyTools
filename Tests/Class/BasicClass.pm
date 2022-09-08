package BasicClass;
{
    use strict;
    use warnings;
    use feature 'say';
    use TinyTools::Class::Accessor;
    
    my $category = TinyTools::Class::Accessor
        ->new
        ->default( "Other" )
        ->static
        ->build;

    my $title = TinyTools::Class::Accessor
        ->new
        ->public
        ->readonly
        ->default( "Item" )
        ->build;
    
    my $description = TinyTools::Class::Accessor
        ->new
        ->public
        ->readonly
        ->build;
   
    my $price = TinyTools::Class::Accessor
        ->new
        ->public
        ->default( 1 )
        ->non_nullable
        ->build;
    
    my $count = TinyTools::Class::Accessor
        ->new
        ->private
        ->static
        ->default( 0 )
        ->non_nullable
        ->build;

    sub new
    {
        return bless( { }, shift );
    }

    sub set_count
    {
        my $cls = shift;

        $cls->count( shift );
    }

    sub get_count
    {
        my $cls = shift;

        return $cls->count;
    }
};
1;