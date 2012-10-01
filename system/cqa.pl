#!/usr/bin/perl

use strict;
use Switch;
use QA; 
use User;
use Rating;

# define state variables
my $state = 'begin';

# QA subsystem
my $qa = new QA();
my $user = new User();
my $rating = new Rating();

# variables 
my $uname = "";
my $response = "";


while(1) {
    process($state);
    $response = get_user_response();
    $state = update_state($state, $response);
}

sub process {
    switch($state) {
	case('begin') {
	    print "Starting new round\n\n";
	    print "Type 'skip' as answer to skip any question.\nType 'quit' to exit at any point of time.\n\n";
	    print "Please enter your username (alphanumeric with no spaces) : ";

	} 
	case('got_name') {
	    print "Hi ".$uname."! ";
	    print "Your current score is (".$user->get_user_stats($uname).")\n\n";
	    print $qa->get_question()." :  ";
	    $state = 'waiting_for_answer';
	}
	case('invalid_name') {
	    print "Invalid response, please enter again: ";
	} 

	case('answered_na') {
	    print "Thanks for your answer, we don't have an answer in system\n\n";
	    print_user_answers();

	    print "Current score: ".$user->get_user_stats($uname)."\n\n";
	    print $qa->get_question()." : ";
	    $state = 'waiting_for_answer';
	} 

	case('answered_true') {
	    print "Correct!\n";
	    print "Current score: ".$user->get_user_stats($uname)."\n\n";
	    print $qa->get_question()." : ";
	    $state = 'waiting_for_answer';
	}
	
	case('answered_false') {
	    print "Incorrect\n\n";
	    print_user_answers();
	    print "Try this question again? [y/n] : ";
	    $state = 'retry';
	}

	case('skip') {
	    if($qa->has_answer) {
		print "Correct answers are ".$qa->get_answer()."\n";
	    } else {
		print "We don't have a correct answer in our system.\n\n";
		print_user_answers();
	    }

	    print "Current score: ".$user->get_user_stats($uname)."\n\n";
	    print $qa->get_question()." : ";
	    $state = 'waiting_for_answer';
	}

	case('quit_with_answer') {
	    if($qa->has_answer) {
		print "Correct answers are ".$qa->get_answer()."\n";
	    } else {
		print "We don't have a correct answer in our system.\n";
		print_user_answers();
	    }
	    print "Bye!";
	    exit;
	}

	case('retry_yes') {
	    $state = 'waiting_for_answer';
	}

	case('retry_no') {
	    if($qa->has_answer) {
		print "\nCorrect answers are ".$qa->get_answer()."\n";
	    } else {
		print "\nWe don't have a correct answer in our system.\n";
		print_user_answers();
	    }

	    print "Current score: ".$user->get_user_stats($uname)."\n\n";
	    print $qa->get_question()." : ";
	    $state = 'waiting_for_answer';
	}

	case('quit') {
	    print "Bye!";
	    exit;
	}

	else {
	    print "error!";
	    exit;
	}
    }
}


sub get_user_response {
    my $input = <STDIN>;
    chomp($input);
    while($input eq "") {
	print "No input received : ";
	$input = <STDIN>;
	chomp($input);
    }

    if($state eq "retry") {
	while(!($input =~ m/^[yn]$/i)) {
	    print "Please enter either y or n : ";
	    $input = <STDIN>;
	    chomp($input);
	}
    }
    return $input;
}

sub update_state {
    my $state = shift;
    my $response = shift;

    $response = lc($response);
    if($state eq "retry" && $response eq 'y' ) {
	print "\nPlease enter new answer here: ";
	return "retry_yes";
    }
    if($state eq "retry" && $response eq 'n' ) {
	return "retry_no";
    }

    if($response eq 'quit') {
	return ($state eq 'waiting_for_answer') ? 'quit_with_answer' : 'quit';
    }

    if($state eq 'begin' || $state eq 'invalid_name') {
	if($response =~ m/^[a-zA-Z0-9]+$/) {
	    $uname = $response;
	    return "got_name";
	} else {
	    return "invalid_name";
	}
    }

    if($state eq 'waiting_for_answer') {
	if($response eq 'skip') {
	    return $response;
	} else {
	    my $result = $qa->check_answer($response);

	    if($result eq "na") {
		$user->record_user_answer($uname, $qa->get_qid(), $response, 0);
		return "answered_na";
	    } elsif($result eq "true") {
		$user->record_user_answer($uname, $qa->get_qid(), $response, 1);
		$user->update_scores($uname, 1);
		return "answered_true";
	    } elsif($result eq "false") {
		$user->record_user_answer($uname, $qa->get_qid(), $response, 0);
		$user->update_scores($uname, 0);
		return "answered_false";
	    }
	}
    }
}

sub print_user_answers {
    my $answers = $user->get_user_answers($qa->get_qid);
    if($answers ne "") {
	print "Other people have answered:".$answers."\n";
    } else {
	print "There are no user responses available at this time\n";
    }
}
