class ErrorConstants {
    static final _prefix = "Invalid: ";

    static final WRONG_ARGUMENT = "Wrong argument";
    static final WRONG_COMMAND = "Please insert a valid command";

    static final TARGET_USER_NOT_FOUND = _prefix + "Target user not found";
    static final USER_NOT_FOUND = _prefix + "User not found";
    static final USER_NOT_LOGGED_IN = _prefix + "Please login first!";
    static final USER_NOT_LOGGED_OUT = _prefix + "Please logout first!";

    static final EMPTY_NAME = _prefix + "Name cannot be empty";

    static final NEGATIVE_AMOUNT = _prefix + "Amount must be higher than 0";
    static final INVALID_AMOUNT = _prefix + "Amount is not a number or dollar currency";
    static final INVALID_FINAL_BALANCE = _prefix + "Your final balance cannot be less than zero (0)";
}
