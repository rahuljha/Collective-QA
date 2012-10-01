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

$rating->print_rating_data(1077);

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

	    if($user->has_user_answers($qa->get_qid)) {
		print "\nRate other people's answers? [y/n] : ";
		$state = "rating";
	    } else {
		print "\nCurrent score: ".$user->get_user_stats($uname)."\n\n";
		print $qa->get_question()." : ";
		$state = 'waiting_for_answer';
	    }
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
	    print "\nTry this question again? [y/n] : ";
	    $state = 'retry';
	}

	case('skip') {
	    if($qa->has_answer) {
		print "\nCorrect answers are ".$qa->get_answer()."\n";
	    } else {
		print "\nWe don't have a correct answer in our system.\n\n";
		print_user_answers();
	    }

	    if($user->has_user_answers($qa->get_qid)) {
		print "\nRate other people's answers? [y/n] : ";
		$state = "rating";
	    } else {
		print "Current score: ".$user->get_user_stats($uname)."\n\n";
		print $qa->get_question()." : ";
		$state = 'waiting_for_answer';
	    }

	}

	case('quit_with_answer') {
	    if($qa->has_answer) {
		print "Correct answers are ".$qa->get_answer()."\n";
	    } else {
		print "We don't have a correct answer in our system.\n";
		print_user_answers();
	    }
	    print "Bye!\n";
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

	    if($user->has_user_answers($qa->get_qid)) {
		print "\nRate other people's answers? [y/n] : ";
		$state = "rating";
	    } else {
		print "Current score: ".$user->get_user_stats($uname)."\n\n";
		print $qa->get_question()." : ";
		$state = 'waiting_for_answer';
	    }
	}

	case('rating_yes') {
	    print "\nYou can rate people's answers either 1 or 0. 1 counts as an upvote and 0 as a downvote.\nType 'done' when finished rating.\n\n";
	    print $rating->print_rating_data($qa->get_qid);
	    print "\nEnter a new score in this format [answer_number score], e.g., [1 1] or type 'done': ";
	    $state = "in_rating";
	}

	case('got_rating') {
	    print "\n".$rating->print_rating_data($qa->get_qid);
	    print "\nEnter a new score in this format [answer_number score], e.g., [1 1] or type 'done': ";
	    $state = "in_rating";
	}

	case('done_rating') {
	    print "\nThanks for your ratings.\n\n";
	    print $qa->get_question()." : ";
	    $state = 'waiting_for_answer';
	}

	case('rating_no') {
	    print $qa->get_question()." : ";
	    $state = 'waiting_for_answer';
	}

	case('quit') {
	    print "Bye!\n";
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

    if($state eq "retry" || $state eq "rating") {
	while(!($input =~ m/^[yn]$/i)) {
	    print "Please enter either y or n : ";
	    $input = <STDIN>;
	    chomp($input);
	}
    }
    if($state eq "in_rating") {
	while(!($input =~ m/^\[?\d+\s+[01]\]?$/i || $input eq 'done' || $input eq 'quit')) {
	    print "Please enter score in this format [answer_number score] or type 'done' to finish rating: ";
	    $input = <STDIN>;
	    chomp($input);
	}
    }
    return $input;
}

sub update_state {
    my $state = shift;
    my $response = shift;

    if($response eq 'quit') {
	return ($state eq 'waiting_for_answer') ? 'quit_with_answer' : 'quit';
    }

    $response = lc($response);
    if($state eq "retry" && $response eq 'y' ) {
	print "\nPlease enter new answer here: ";
	return "retry_yes";
    }
    if($state eq "retry" && $response eq 'n' ) {
	return "retry_no";
    }

    if($state eq "rating" && $response eq 'y') {
	return "rating_yes";
    }

    if($state eq "rating" && $response eq 'n') {
	return "rating_no";
    }

    if($state eq "in_rating") {
	if($response eq 'done') {
	    return "done_rating";
	} else {
	    $response =~ m/^\[?(\d+)\s+([01])\]?$/i;
	    my $aid = $1;
	    my $score = $2;
	    my $success = $rating->update_rating($qa->get_qid, $aid, $score);
	    if(!$success) {
		print "\nError, could not update rating.\n\n";
	    }
	    return "got_rating";
	}
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
