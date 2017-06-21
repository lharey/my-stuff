#!/usr/bin/env perl

use v5.22;
use strict;
use warnings;
use FindBin;
use Getopt::Long::Descriptive;
use UML::Class::Simple;
use Path::Tiny;
use Cpanel::JSON::XS;

my ($opt, $usage) = describe_options(
    '%c %o',
    ['dump|d' => 'Dumps the UML::Class::Simple DOM tree to json file' ],
    ['create|c' => 'Creates a png image using UML::Class::Simple' ],
    ['dom_json|j=s' => 'Json file of a UML::Class::Simple DOM tree to use in conjunction with create to produce a png' ],
    ['help'    => 'Print usage and exit']
);

print($usage->text) and exit if $opt->help;

if ($opt->dump) {
    dump_dom();
}
elsif ($opt->create) {
    create_png();
}

sub dump_dom {
    my $iter = path($FindBin::Bin,'..','lib')->iterator({ recurse => 1 });

    my @files;
    while ( my $path = $iter->() ) {
        if ($path->basename =~ /\.pm$/) {
            push @files, $path->canonpath;
        }
    }

    my @classes = classes_from_files(\@files);
    my $painter = set_options(UML::Class::Simple->new(\@classes));

    my $json_file =  path($FindBin::Bin,'..','uml_'. time() . '.json');
    $json_file->spew(encode_json $painter->as_dom());
    say "JSON: ", $json_file->canonpath;
}

sub create_png {
    die "Must provide -j with path to Json file of a UML::Class::Simple DOM tree" if !$opt->dom_json;

    my $dom = decode_json path($opt->dom_json)->slurp();

    my $painter = set_options(UML::Class::Simple->new());
    $painter->set_dom($dom);

    my $png_file = path($FindBin::Bin,'..','uml_'. time() . '.png');
    $painter->as_png($png_file->canonpath);
    say "JSON: ", $png_file->canonpath;
}

sub set_options {
    my ($painter) = @_;

    $painter->inherited_methods(0);
    $painter->public_only(1);
    $painter->moose_roles(1);
    $painter->display_inheritance(1);

    return $painter;
}
