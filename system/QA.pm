package QA;

use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_question get_qid);

my $base_dir = "/data0/projects/collective_qa/system";
my $qfile = $base_dir."/questions.txt";
my $afile = $base_dir."/answers.txt";

my %questions = ();
my %answers = ();

my $cqid = "";
my %visited = ();
my @qkeys = ();

sub new {
    load_questions();
    load_answers();
    @qkeys = keys %questions;
    my $self = {};
    bless $self;
}

sub get_question {
    my $self = shift;
    
    my $qidx = int(rand(@qkeys));
    while(exists $visited{$qidx}) {
	$qidx = int(rand(@qkeys));
    }
    $visited{$qidx} = 1;

    my $qid = $qkeys[$qidx];
    $cqid = $qid;
    return $questions{$qid};
}

sub has_answer {
    return exists $answers{$cqid};
}

sub get_answer {
    my $self = shift;
    my $answer = "";    

    for my $apat (@{$answers{$cqid}}) {
	$apat =~ s/\.\*/ /g;
	$apat =~ s/\\\-/-/g;
	$apat =~ s/(\([^\|]*\s*)\|\s*[^\)]*\)/$1/g;
	$apat =~ s/[\(\)]//g;
	$apat =~ s/\\s\*//g;
	$apat =~ s/\?//g;
	
	$answer .= "'$apat' ";
    }
    return $answer;
}

sub check_answer {
    my $self = shift;
    my $answer = shift;

    if(!exists $answers{$cqid}) {
	return "na";
    }
    my $correct_answers = $answers{$cqid};
    foreach my $ta (@$correct_answers) {
	return "true" if $answer =~ m/$ta/i;
    }
    return "false";
}

sub get_qid {
    return $cqid;
}

sub load_questions {
    open QFILE, $qfile or die $!;
    while(<QFILE>) {
	chomp($_);
	my ($qid, $qtext) = split(/ ::: /, $_);
	$questions{$qid} = $qtext;
    }
    close QFILE;
}

sub load_answers {
    open AFILE, $afile or die $!;
    while(<AFILE>) {
	chomp($_);
	$_ =~ m/^(\d+)\s+(.*)$/;
	my $aid = $1;
	my $apat = $2;
	$answers{$aid} = [] unless exists $answers{$aid};
	push(@{$answers{$aid}}, $apat);
    }
    close AFILE;
}

1;
