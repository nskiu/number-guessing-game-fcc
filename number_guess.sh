#! /bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))

echo -e "\n~~~ Number Guessing Game ~~~\n"

MAIN_MENU(){
  echo "Enter your username:"
  read USERNAME

  PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE username = '$USERNAME'")
  # if username is not in database
  if [[ -z $PLAYER_ID ]]
  then
    INSERT_RESULT=$($PSQL "INSERT INTO players(username) VALUES('$USERNAME')")
    if [[ $INSERT_RESULT == "INSERT 0 1" ]]
    then
      PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE username = '$USERNAME'")
      INSERT_STATS=$($PSQL "INSERT INTO stats(player_id) VALUES($PLAYER_ID)")
      if [[ $INSERT_STATS == "INSERT 0 1" ]]
      then
        GAMES_PLAYED=0
        BEST_GAME=0
        echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
      fi
    fi
  else
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM stats WHERE player_id = $PLAYER_ID")
    BEST_GAME=$($PSQL "SELECT best_game FROM stats WHERE player_id = $PLAYER_ID")
    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi

  GAME
}

GAME(){
  echo -e "\nGuess the secret number between 1 and 1000:"
  read GUESS
  GUESS_COUNT=1
  while [[ ! $GUESS == $SECRET_NUMBER ]]
  do
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo -e "\nThat is not an integer, guess again:"
      read GUESS
    elif [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      echo -e "\nIt's higher than that, guess again:"
      read GUESS
    else
      echo -e "\nIt's lower than that, guess again:"
      read GUESS
    fi
    ((GUESS_COUNT++))
  done
  echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

  # update player data
  ((GAMES_PLAYED++))
  if [[ $GUESS_COUNT -lt $BEST_GAME || $BEST_GAME == 0 ]]
  then
    BEST_GAME=$GUESS_COUNT
  fi
  UPDATE_RESULT=$($PSQL "UPDATE stats SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE player_id = $PLAYER_ID")
}

MAIN_MENU
