#!/usr/bin/perl

my $nr  = $ARGV[0];
my $par = $ARGV[1];

my $file = sprintf("page_%04d.txt", $nr);
my $ffile = "fav.txt";
my $rfile = "rej.txt";

open(IN, "<$file") or  die "Cannot open file \"$file\": $!\n";
open(FA, "<$ffile") or die "Cannot open file \"$ffile\": $!\n";
open(RF, "<$rfile") or die "Cannot open file \"$rfile\": $!\n";

my (%data, %fav, %rej);

while(<FA>) { chomp; $fav{$_} = 1; } close(FA);
while(<RF>) { chomp; $rej{$_} = 1; } close(RF);

my $count = 0;
while(<IN>) {
    chomp;
    my $fstat = 0;
    my $rstat = 0;
    my $char = "-";

    $fstat = 1 if (exists $fav{$_});
    $rstat = 1 if (exists $rej{$_});

    if (($fstat eq 1) and ($rstat eq 1)) { $char = "b"; }
    if (($fstat eq 1) and ($rstat eq 0)) { $char = "+"; }
    if (($fstat eq 0) and ($rstat eq 1)) { $char = "x"; }

    $count++;
    if ( $par eq $char ) { printf("%s %02d %s\n", $char, $count, $_); }
    if ( ! $par )        { printf("%s %02d %s\n", $char, $count, $_); }
}
close(IN);
