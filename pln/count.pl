#!/usr/bin/perl -w
# Change above line to point to your perl binary

use Path::Class;
use CGI ':standard';
use GD::Graph::area;
use GD::Graph::bars;
use strict;

my @dataX;
my @dataY;

for my $file (@ARGV) {
	open(FILE, '<', $file) or do {
		warn "can't open $file\n";
	};
	
	my $type = +(split "_" , $file)[1];
	
	my $nrLines = 0;
	my $nrFiles = 0;
	for my $file_source (<FILE>) {
		$nrFiles++;
		$file_source =~ s/\n//g; 
		$file_source =~ s/\r//g; 
		
		my $file_source_name = file($file_source);
		$file_source_name =~ $file_source_name->stringify;
		open(FILESOURCE,'<',$file_source_name) or do {
			warn "can't open $file_source_name\n";
		};
		$nrLines++ while <FILESOURCE>;
	}
	
	push(@dataX,$nrLines);
	push(@dataY,$type);

#	print "temos $nrLines linhas em $nrFiles ficheiros de $type \n";
}

my @data;
push(@data,[@dataY]);
push(@data,[@dataX]);

my $mygraph = GD::Graph::bars->new(500, 300);
$mygraph->set(
	x_label     => 'Languages',
	y_label     => 'Number of lines',
	title       => 'Number of lines per language',
) or warn $mygraph->error;

my $myimage = $mygraph->plot(\@data) or die $mygraph->error;
print $myimage->png;

