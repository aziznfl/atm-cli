import "dart:math";

import "package:atm/utils/extensions/int.dart";
import "package:atm/utils/extensions/string.dart";

class User {
    final String name;
    int balance;
    List<UserTransaction> debts;
    List<UserTransaction> pendingNotification;

    User(this.name, this.balance, this.debts, this.pendingNotification);

    String get showName {
        return name.toCapitalize();
    }

    String get showBalance {
        return balance.toCurrency();
    }
}

class UserTransaction {
    final User user;
    int amount;

    UserTransaction(this.user, this.amount);

    String get showName {
        return user.name.toCapitalize();
    }

    String get showAmount {
        return amount.abs().toCurrency();
    }
}
