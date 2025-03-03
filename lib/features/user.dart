import "package:atm/domains/usecase/user.dart";
import "package:atm/entities/exceptions/result.dart";
import "package:atm/entities/models/user.dart";
import "package:atm/utils/extensions/int.dart";
import "package:atm/utils/extensions/list.dart";
import "package:atm/utils/extensions/string.dart";
import "package:atm/utils/constants.dart";

class UserController {
    UserUseCase _useCase = UserUseCase();
    User? currentUser;

    Result<String> login(String name) {
        if (name.isEmpty) return Result(errorMessage: ErrorConstants.EMPTY_NAME);

        // check if user loggin with same name
        if (currentUser != null) {
            if (currentUser?.name == name) return Result(data: _generateGreetings());
            else return Result(errorMessage: ErrorConstants.USER_NOT_LOGGED_OUT);
        }

        currentUser = _useCase.getUser(name);

        if (currentUser == null) {
            final newUser = _useCase.addNewUser(name);
            if (newUser == null) return Result(errorMessage: ErrorConstants.EMPTY_NAME);

            currentUser = newUser;
        }

        return Result(data: _generateGreetings());
    }

    Result<String> logout() {
        if (currentUser == null) return Result(errorMessage: ErrorConstants.USER_NOT_LOGGED_IN);

        final name = currentUser?.showName;
        currentUser = null;
        return Result(data: "Goodbye, $name");
    }

    Result<String> deposit(String amountText) {
        final amount = int.tryParse(amountText);
        if (amount == null) return Result(errorMessage: ErrorConstants.INVALID_AMOUNT);
        if (amount < 1) return Result(errorMessage: ErrorConstants.NEGATIVE_AMOUNT);

        final user = currentUser;
        if (user == null) return Result(errorMessage: ErrorConstants.USER_NOT_FOUND);

        final usersPaid = _useCase.increaseBalance(user, amount);

        var str = "";
        usersPaid.forEach((user) {
            str += "Transferred ${user.showAmount} to ${user.showName}\n";
        });
        str += "Your balance is ${currentUser?.showBalance}";
        currentUser?.debts.forEach((debt) {
            str += "\nOwed ${debt.showAmount} to ${debt.showName}";
        });

        return Result(data: str);
    }

    Result<String> withdraw(String amountText) {
        final amount = int.tryParse(amountText);
        if (amount == null) return Result(errorMessage: ErrorConstants.INVALID_AMOUNT);
        if (amount < 1) return Result(errorMessage: ErrorConstants.NEGATIVE_AMOUNT);

        if (currentUser == null) return Result(errorMessage: ErrorConstants.USER_NOT_FOUND);

        final isSucceed = _useCase.decreaseBalance(currentUser!, amount);
        if (!isSucceed) return Result(errorMessage: ErrorConstants.INVALID_FINAL_BALANCE);

        return Result(data: "Your balance is ${currentUser?.showBalance}");
    }

    Result<String> transfer(String amountText, String targetName) {
        int? amount = int.tryParse(amountText);
        if (amount == null) return Result(errorMessage: ErrorConstants.INVALID_AMOUNT);
        if (amount < 1) return Result(errorMessage: ErrorConstants.NEGATIVE_AMOUNT);

        final user = currentUser;
        if (user == null) return Result(errorMessage: ErrorConstants.USER_NOT_FOUND);

        final targetUser = _useCase.getUser(targetName);
        if (targetUser == null) return Result(errorMessage: ErrorConstants.TARGET_USER_NOT_FOUND);

        if (user == targetUser) return Result(errorMessage: "Invalid: Same user");

        // transfer
        final transferred = _useCase.transfer(user, targetUser, amount);
        if (transferred == null) return Result(errorMessage: "Failed transfer");

        // set debtAmount
        final debtAmount = amount - transferred;

        // set log
        var str = "";
        if (transferred > 0) str += "Transfered ${transferred.toCurrency()} to ${targetUser.showName}\n";
        str += "Your balance is ${currentUser?.showBalance}";

        // set debts log
        user.debts.forEach((transaction) {
            if (transaction.user == targetUser) str += "\nOwed ${transaction.showAmount} to ${targetUser.showName}";
        });

        // set receivables log
        final receivables = _useCase.receivables(user);
        receivables.forEach((transaction) {
            if (transaction.user == targetUser) str += "\nOwed ${transaction.showAmount} from ${targetUser.showName}";
        });

        return Result(data: str);
    }
}

extension ResponseUserController on UserController {
    String _generateGreetings() {
        final user = currentUser;
        if (user == null) return "";

        var str = "Hello, ${user.showName}";

        // print pending notifications
        final pendingNotifications = user.pendingNotifications;
        for (var transaction in pendingNotifications) {
            if (transaction.amount > 0) {
                str += "\nReceived ${transaction.showAmount} from ${transaction.showName}";
            } else if (transaction.amount < 0) {
                str += "\nTransferred ${transaction.showAmount} to ${transaction.showName}";
            }
        }
        pendingNotifications.clear();

        str += "\nYour balance is ${user.showBalance}";

        // get debts
        final debts = user.debts;
        if (debts.isNotEmpty) {
            debts.forEach((debt) {
                str += "\nOwed ${debt.showAmount} to ${debt.user.showName}";
            });
        }

        // get receivables
        final receivables = _useCase.receivables(user);
        if (receivables.isNotEmpty) {
            receivables.forEach((receive) {
                str += "\nOwed ${receive.showAmount} from ${receive.user.showName}";
            });
        }

        return str;
    }
}
