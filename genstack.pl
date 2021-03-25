#!/usr/bin/env perl

# Created by tharchen with a ton of <3

# usage: ./genstack.pl stacksize min max
# exemple: ./genstack.pl 10 0 1000
# will creates 10 uniques numbers from 0 to 1000
# like: 138 527 947 967 811 33 112 526 949 27
# enjoy :)

$stacksize = $ARGV[0];
$min = $ARGV[1];
$max = $ARGV[2];
@stack = ();

if (!$$stacksize || !$min || !$max || $stacksize < 0 || $min >= $max)
{
	print "Usage: ./genstack.pl stacksize min max";
}

for($num = 0; $num < $stacksize; )
{
	$n = int(srand() % ($max - $min + 1) + $min);
	if (!(grep { $_ eq $n } @stack))
	{
		push @stack, $n;
		$num++;
	}
}
print "@stack\n";
