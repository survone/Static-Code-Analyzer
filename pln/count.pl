#!/usr/bin/perl

use Path::Class;
use GD::Graph::bars;

my @_dataNrLines;
my @_dataNrFiles;
my @_dataRatioNrFilesNrLines;
my @_dataTypes;

# type => [nrFiles,nrLines]
my %_types = ("tcl" => [0,0] , "cpp" => [0,0], "c" => [0,0], "hs" => [0,0], "java" => [0,0], "pl" => [0,0], "py" => [0,0], "rb" => [0,0],
              "tex" => [0,0], "xml" => [0,0], "xsl" => [0,0]);
my $_filePath = $ARGV[0];
my @_files = getAllFiles($_filePath);

for my $type (keys %_types) {
	print "Working on $type...\n";
	for my $file_source ( getFiles($type) ) {
		chomp $file_source;
		$_types{$type}[0]++;

		my $file_source_name = file($file_source);
		$file_source_name =~ $file_source_name->stringify;
		open(FILESOURCE,'<',$file_source_name) or warn "can't open $file_source_name\n";
		$_types{$type}[1]++ while <FILESOURCE>;
	}
	
	if($_types{$type}[0] != 0) {
		push(@_dataRatioNrFilesNrLines,$_types{$type}[1] / $_types{$type}[0]);
		push(@_dataNrLines,$_types{$type}[1]);
		push(@_dataTypes,$type);
		push(@_dataNrFiles,$_types{$type}[0]);
	}
}

plotToPng("LinesPerLanguage.png",[@_dataTypes],[@_dataNrLines],"Languages", "Number of lines", "Number of lines per language");
plotToPng("FilesPerLanguage.png",[@_dataTypes],[@_dataNrFiles],"Languages", "Number of files", "Number of files per language");
plotToPng("RatioFilesLines.png",[@_dataTypes],[@_dataRatioNrFilesNrLines],"Languages", "Number of lines per file", "Ratio of nr lines/nr files per language");

# plotToPng(FileName,dataX,dataY,x_label,y_label,title)
sub plotToPng {
	my $fileName = $_[0];
	my $dX = $_[1];
	my $dY = $_[2];
	my $x_label = $_[3];
	my $y_label = $_[4];
	my $title = $_[5];

	my @data;
	push(@data,$dX);
	push(@data,$dY);

	my $mygraph = GD::Graph::bars->new(500, 300);
	$mygraph->set(
		transparent   => 1,

		# show the values for each bar in integer format separated 10 pixels from the top of the bar
		show_values   => 1,
		values_format => sub { return sprintf("\%d", shift); } ,
		values_space  => 10,

		x_label       => $x_label,
		y_label       => $y_label,
		title         => $title,
		dclrs         =>  [ qw(gold red green) ],
	) or warn $mygraph->error;

	my $myimage = $mygraph->plot(\@data) or warn $mygraph->error;
	
	open (IMG, '>' , $fileName);
	binmode IMG;
	print IMG $myimage->png;
	close (IMG);
}

sub fun {
	my $value = shift;
	return sprintf("\%d", int($_));
}

sub getAllFiles {
	my $path = $_[0];

	opendir (DIR, $path) or warn "can't open $path\n";

	my @files =
		map { $path . '/' . $_ }
		grep { !/^\.{1,2}$/ }
		readdir (DIR);

	closedir(DIR);

	return
		map {
				if((-d $_) && (-r $_)) {
					getAllFiles ($_);
				} elsif((-r $_) && (-T $_)) {
					$_;
				}
			}
		@files;
}

sub getFiles {
	my $ext = $_[0];

	return grep { /\.$ext$/ } @_files;
}
