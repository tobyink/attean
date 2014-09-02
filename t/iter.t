use Test::More;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean;
use Type::Tiny;

my $Int = Type::Tiny->new(
	name       => "Int",
	constraint => sub { /^(\d+)$/ },
	message    => sub { "$_ isn't an integer" },
);

{
	note('ListIterator[Attean::Triple]');
	my $s	= Attean::Blank->new('x');
	my $p	= Attean::IRI->new('http://example.org/p');
	my $o1	= Attean::Literal->new(value => '1', datatype => 'http://www.w3.org/2001/XMLSchema#integer');
	my $o2	= Attean::Literal->new(value => '2', datatype => 'http://www.w3.org/2001/XMLSchema#integer');
	
	my $t1	= Attean::Triple->new($s, $p, $o1);
	my $t2	= Attean::Triple->new($s, $p, $o2);
	my $i	= Attean::ListIterator->new(values => [$t1, $t2], item_type => Type::Tiny::Role->new(role => 'Attean::API::Triple'));
	does_ok($i, 'Attean::API::Iterator');
	isa_ok($i, 'Attean::ListIterator');
	
	my $x1	= $i->next;
	does_ok($x1, 'Attean::API::Triple');
	
	my $x2	= $i->next;
	does_ok($x2, 'Attean::API::Triple');
	
	is($i->next, undef, 'eof');
}

{
	note('ListIterator[Term != Triple]');
	my $p	= Attean::IRI->new('http://example.org/p');
	my $g	= Attean::IRI->new('http://example.org/g');
	dies_ok {
		my $i	= Attean::ListIterator->new(values => [$p, $g], item_type => Type::Tiny::Role->new(role => 'Attean::API::Triple'));
	};
}

{
	note('ListIterator[Int != Triple]');
	dies_ok {
		my $i	= Attean::ListIterator->new(values => [1, 2, 3], item_type => Type::Tiny::Role->new(role => 'Attean::API::Triple'));
	};
}

{
	note('CodeIterator[Int]->map<Int>');
	my $value	= 0;
	my $code	= sub { return ++$value };
	my $iter	= Attean::CodeIterator->new( generator => $code, item_type => $Int );
	is($iter->next, 1, 'expected value');
	is($iter->next, 2, 'expected value');
	is($iter->next, 3, 'expected value');
	my $double	= $iter->map(sub { $_ * 2 });
	does_ok($double, 'Attean::API::Iterator');
	isa_ok($double->item_type, 'Type::Tiny');
	is($double->item_type->name, 'Int', 'expected item_type');
	is($double->next, 8, 'expected value');
	is($double->next, 10, 'expected value');
}

{
	note('CodeIterator[Int]->map<Literal>');
	my $value	= 0;
	my $code	= sub { return ++$value };
	my $iter	= Attean::CodeIterator->new( generator => $code, item_type => $Int );
	my $ints	= $iter->map(
		sub { Attean::Literal->new(value => $_, datatype => 'http://www.w3.org/2001/XMLSchema#integer') },
		Type::Tiny::Role->new(role => 'Attean::API::Literal')
	);
	does_ok($ints, 'Attean::API::Iterator');
	isa_ok($ints->item_type, 'Type::Tiny::Role');
	is($ints->item_type->role, 'Attean::API::Literal', 'expected item_type');
	
	my $l1	= $ints->next;
	does_ok($l1, 'Attean::API::Literal');
	is($l1->value, '1', 'expected value');
	is($l1->datatype->value, 'http://www.w3.org/2001/XMLSchema#integer', 'expected literal datatype');
	
	my $l2	= $ints->next;
	does_ok($l2, 'Attean::API::Literal');
	is($l2->value, '2', 'expected value');
}

{
	note('ListIterator[Int]->grep');
	my $value	= 0;
	my $code	= sub { return ++$value };
	my $iter	= Attean::ListIterator->new(values => [1, 2, 3, 4, 5], item_type => $Int);
	my $evens	= $iter->grep(sub { $_ % 2 == 0 });
	does_ok($evens, 'Attean::API::Iterator');
	isa_ok($evens->item_type, 'Type::Tiny');
	is($evens->item_type->name, 'Int', 'expected item_type');
	is($evens->next, 2, 'expected value');
	is($evens->next, 4, 'expected value');
	is($evens->next, undef, 'expected eof');
}

{
	note('ListIterator[Int] reset');
	my $value	= 0;
	my $code	= sub { return ++$value };
	my $iter	= Attean::ListIterator->new(values => [1, 2], item_type => $Int);
	does_ok($iter, 'Attean::API::RepeatableIterator');
	is($iter->next, 1, 'expected value');
	is($iter->next, 2, 'expected value');
	$iter->reset;
	is($iter->next, 1, 'expected value after reset');
	is($iter->next, 2, 'expected value');
	is($iter->next, undef, 'expected eof');
}

done_testing();


sub does_ok {
    my ($class_or_obj, $does, $message) = @_;
    $message ||= "The object does $does";
    ok(eval { $class_or_obj->does($does) }, $message);
}

