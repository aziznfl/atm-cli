import "dart:math";

import "package:atm/core/configs.dart";
import "package:atm/entities/models/user.dart";
import "package:atm/utils/extensions/list.dart";

class UserUseCase {
    List<User> _users = [];

    User? getUser(String name) {
        return _users.firstWhereOrNull((user) => user.name == name);
    }

    User? addNewUser(String name) {
        if (name.isEmpty) return null;

        final newUser = User(name.toLowerCase(), 0, [], []);
        _users.add(newUser);
        return newUser;
    }
}

extension TransactionsUserUseCase on UserUseCase {
    List<UserTransaction> increaseBalance(User user, int amount) {
        user.balance += amount;

        return _payDebts(user);
    }

    bool decreaseBalance(User user, int amount) {
        if (amount > user.balance) return false;

        user.balance -= amount;
        return true;
    }

    int? transfer(User fromUser, User toUser, int amount) {
        if (amount < 1) return null;

        // get existing debt and
        final existingDebt = toUser.debts.firstWhereOrNull((transaction) => transaction.user == fromUser);
        if (existingDebt != null && existingDebt.amount > 0) {
            final deduct = min(amount, existingDebt.amount);
            final leftOver = amount - deduct;

            final debtFinal = existingDebt.amount - deduct;
            if (debtFinal == 0) {
                // remove if final amount is zero
                toUser.debts.remove(existingDebt);
            } else {
                // reduce the existing debt
                existingDebt.amount = debtFinal;
            }

            if (leftOver > 0) return transfer(fromUser, toUser, leftOver);
            else return -debtFinal;
        }

        var transferred = 0;
        if (fromUser.balance == 0) {
            // create debt as much as [debtPaidAmount]
            _addDebt(fromUser, toUser, amount);
        } else if (fromUser.balance < amount) {
            // create transfer notification
            _addPendingNotifications(toUser, fromUser, fromUser.balance);

            // set transfer amount;
            transferred = fromUser.balance;

            // create as much debt as amount transfer - user balance;
            final debtPaidAmount = amount - transferred;
            _addDebt(fromUser, toUser, debtPaidAmount);
        } else {
            // create transfer notification
            _addPendingNotifications(toUser, fromUser, amount);

            // set transfer amount;
            transferred = amount;
        }

        // adjust balance from both user
        toUser.balance += transferred;
        fromUser.balance -= transferred;

        // pay target user debt
        if (_isUserCanPaidDebt(toUser)) _payDebts(toUser);

        return transferred;
    }

    List<UserTransaction> receivables(User fromUser) {
        List<UserTransaction> receivables = [];
        _users.forEach((user) {
            final debt = user.debts.firstWhereOrNull((debt) => debt.user == fromUser);
            if (debt != null && debt.amount > 0) {
                receivables.add(UserTransaction(user, debt.amount));
            }
        });
        return receivables;
    }

    // Private Method

    bool _isUserCanPaidDebt(User user) {
        return Config.IS_AUTO_PAID_DEBT
            && user.debts.isNotEmpty
            && user.balance > 0;
    }

    void _addDebt(User user, User lender, int amount) {
        if (amount < 1) return;

        final existingDebt = user.debts.firstWhereOrNull((debt) => debt.user == lender);

        if (existingDebt != null) {
            existingDebt.amount += amount;
        } else {
            user.debts.add(UserTransaction(lender, amount));
        }
    }

    List<UserTransaction> _payDebts(User user) {
        if (user.balance < 1 && user.debts.length < 1) return [];

        final payments = <UserTransaction>[];
        final length = user.debts.length;
        var i = 0;
        while(i < length && user.balance > 1) {
            final lenderDebt = user.debts[i];

            final int payAmount = min(user.balance, lenderDebt.amount);
            lenderDebt.amount -= payAmount;

            // transfering amount
            transfer(user, lenderDebt.user, payAmount);

            // create recieve notification
            _addPendingNotifications(user, lenderDebt.user, -payAmount);

            // pay target user debt
            if (_isUserCanPaidDebt(lenderDebt.user)) _payDebts(lenderDebt.user);

            // add for log
            payments.add(UserTransaction(lenderDebt.user, payAmount));

            i++;
        }

        user.debts.removeWhere((debt) => debt.amount == 0);

        return payments;
    }

    void _addPendingNotifications(User fromUser, User toUser, int amount) {
        if (!Config.IS_RECORD_PENDING_NOTIFICATION) return;

        fromUser.pendingNotifications.add(UserTransaction(toUser, amount));
    }
}
