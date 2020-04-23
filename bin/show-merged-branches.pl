#!/usr/bin/env perl
use v5.20;
use warnings;
use Carp qw(croak);

#use Getopt::Long qw(GetOptions);

chomp(my $git_user_name = qx{git config --get user.name});

my @lines = qx{git for-each-ref --format='%(objecttype) %(refname)%(if)%(authorname)%(then) %(authorname)%(end)' --merged=HEAD --sort=authorname};
chomp(@lines);

my %branches_by_author;
my @tags;

LINE:
for my $line (@lines) {
    my ($type, $ref, $author) = split /\s+/, $line, 3;
    if ($type eq 'tag') {
        push @tags, $ref;
        next LINE;
    }

    if ($type eq 'commit') {
        $ref =~ s{^refs/remotes/origin/}{};
        push @{ $branches_by_author{ $author // 'UNKNOWN' } }, $ref;
    }
}

my $total_branches_count = 0;
for my $author (
    reverse sort { scalar @{ $branches_by_author{$a} } <=> scalar @{ $branches_by_author{$b} } }
    keys %branches_by_author
) {
    my $count = scalar @{ $branches_by_author{$author} };
    $total_branches_count += $count;
    printf "$author: %d\n", $count;
    #say "Old branches from $author:",
    #  map {"$_\n"} @{ $branches_by_author{$author} };
}
say "Total number of merged branches: $total_branches_count";

if ($git_user_name) {
    say "\nYour merged branches:";
    print map {"\t$_\n"} @{ $branches_by_author{$git_user_name} };
}
