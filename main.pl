#!/usr/bin/env perl

use v5.18;
use strict;
use warnings;

use File::Basename;
use Getopt::Long;

my $WORD_FILE = '/usr/share/dict/words';

sub HELP {
    my ($defaults) = @_;

    my $bin = basename($0);

    my $help =<<END;
$bin - Generate passwords

Generates a password from a random selection of dictionary words that contains
lower- and upper-case letters and a number.

This program neither endorses regular use of such passwords, nor security
policies that make its existence necessary.

USE:

    $bin [OPTION...]

OPTIONS:

    -w, --words     Number of words to create password from. Default $defaults->{words}.
    -l, --length    Maximum length of words. 0 means no length. Default $defaults->{length}.
    -h, --help      Print this message and exit
END

    return $help;
}

sub getWords {
    my ($word_file) = @_;

    my @words = ();

    open my $fh, '<', $word_file or die $!;
    while (my $word = <$fh>) {
        chomp $word;
        push @words, $word;
    }
    close $fh;

    return @words;
}

sub getPasswords {
    my ($words_ref, $filter, $no_words) = @_;

    # default to no filter
    $filter = $filter // sub { 1 };

    my @words = grep { $filter->($_) } @{$words_ref};

    if (not @words) {
        die "No words survived filter";
    }

    my @passwords = ();
    for (my $i = 0; $i < $no_words; $i++) {
        push @passwords, $words[int(rand(@words))];
    }

    return @passwords;
}

sub createPassword {
    my (@words) = @_;

    @words = map { (rand() > 0.5) ? ucfirst($_) : $_ } @words;
    my $num = int(rand(100));
    splice @words, int(rand(@words)), 0, $num; 
    my $password = join('', @words);

    return $password;
}

sub getFilter {
    my ($length) = @_;

    if (not $length) {
        return sub { 1 };
    }

    return sub { length($_) <= $length };
}

sub main {
    my $help;
    my $length = 6;
    my $no_words = 4;
    my $help_msg = HELP({ length => $length, words => $no_words });
    GetOptions(
        "words=i" => \$no_words,
        "length=i" => \$length,
        "help" => \$help,
    ) or die "Command-line argument error";

    if (defined $help) {
        print $help_msg;
        exit 0;
    }

    die "words must be positive" if not $no_words;

    my @words = getWords($WORD_FILE);
    my $filter = getFilter($length);
    my @passwords = getPasswords(\@words, $filter, $no_words);
    my $password = createPassword(@passwords);

    print join(' ', @passwords) . ": $password\n";
}

main();
