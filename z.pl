#!/usr/bin/env perl
#
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Text::CSV;

sub usage {
	die <<"USAGE";
Usage:
  $0 --input INPUT_csv_file --output OUTPUTFILE.ARD.ind --ldd YYYYMMDD

Example:
  $0 --input INPUT_csv_file --output OUTPUTFILE.ARD.ind --ldd 20251216
USAGE
}

my ($input, $output, $ldd);

GetOptions(
	'input=s'  => \$input,
	'output=s' => \$output,
	'ldd=s'    => \$ldd,
) or usage();

usage() unless defined $input && defined $output && defined $ldd;

open my $in,  '<:raw', $input  or die "Cannot open input '$input': $!\n";
open my $out, '>:raw', $output or die "Cannot open output '$output': $!\n";

my $csv = Text::CSV->new({
	binary   => 1,
	sep_char => ';',   # fixed separator
}) or die "Text::CSV->new() failed\n";

# Read and parse header first line
my $header = <$in>;
die "Input '$input' is empty (no header line found)\n" unless defined $header;

# Trim off header line
$header =~ s/[\r\n]+\z//;

$csv->parse($header) or die "Failed to parse header: " . $csv->error_diag() . "\n";
my @hdr = $csv->fields();

# Base offset of 1st data is just after header line, so first data record offset = 0
my $base_offset = tell($in);

while (1) {
	my $pos  = tell($in);   # byte offset before reading line
	my $line = <$in>;
	last unless defined $line;

# get data line/record length excluding newline, sometimes CRNL
	my $len = length($line);
	if ($line =~ /\r\n\z/) {
	    $len -= 2;
	} elsif ($line =~ /\n\z/ || $line =~ /\r\z/) {
	    $len -= 1;
	}

# Trim line endings for parsing
	$line =~ s/[\r\n]+\z//;

# Skip completely empty lines if any
	next if $line eq '';

	$csv->parse($line) or die "CSV parse error at input offset. Please check if data delimiter is ';' ? " . ($pos - $base_offset) .
	                          ": " . $csv->error_diag() . "\nLine: $line\n";
	my @f = $csv->fields();
	my $rel_offset = $pos - $base_offset;

# Print LDD as first occurence as defined by Steven
	print {$out} "GROUP_FIELD_NAME:LDD\n";
	print {$out} "GROUP_FIELD_VALUE:$ldd\n";

# then, Print all fields in occurrence order using header names (fallback FIELD_n for extra ones)
	my $max_i = $#hdr > $#f ? $#hdr : $#f;  # and also prints missing trailing cols as empty

	for my $i (0 .. $max_i) {
	    my $name = $hdr[$i] // '';
	    $name =~ s/^\s+|\s+$//g;
	    $name = ($name ne '') ? uc($name) : ('FIELD_' . ($i + 1));

	    my $value = defined $f[$i] ? $f[$i] : '';   # For null/none fields

	    print {$out} "GROUP_FIELD_NAME:$name\n";
	    print {$out} "GROUP_FIELD_VALUE:$value\n";
	}

# Finally, Print offset, length and filename
	print {$out} "GROUP_OFFSET:$rel_offset\n";
	print {$out} "GROUP_LENGTH:$len\n";
	print {$out} "GROUP_FILENAME:$input\n";
}

# End
close $in  or die "Error closing input: $!\n";
close $out or die "Error closing output: $!\n";
