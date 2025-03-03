import "package:test/test.dart";

import "package:atm/entities/models/user.dart";
import "package:atm/features/user.dart";
import "package:atm/utils/constants.dart";

void main() {
    group("UserController Tests", () {
        group("login()", () {
            test("succeed", () {
                final controller = UserController();

                final result = controller.login("john");

                expect(result.errorMessage, "");
                expect(controller.currentUser?.name, "john");
            });

            test("succeed when double login", () {
                final controller = UserController();

                var result = controller.login("emi");
                expect(result.errorMessage, "");
                expect(controller.currentUser?.name, "emi");

                result = controller.login("emi");
                expect(result.errorMessage, "");
                expect(controller.currentUser?.name, "emi");
            });

            test("failed when change user", () {
                final controller = UserController();

                var result = controller.login("emi");
                expect(result.errorMessage, "");
                expect(controller.currentUser?.name, "emi");

                result = controller.login("john");
                expect(result.errorMessage, ErrorConstants.USER_NOT_LOGGED_OUT);
                expect(controller.currentUser?.name, "emi");
            });

            test("failed", () {
                final controller = UserController();

                final result = controller.login("");

                expect(result.errorMessage, ErrorConstants.EMPTY_NAME);
                expect(controller.currentUser, isNull);
            });
        });

        group("logout()", () {
            test("succeed", () {
                final controller = UserController();
                controller.login("john");

                final result = controller.logout();

                expect(result.errorMessage, "");
                expect(controller.currentUser, isNull);
            });

            test("failed", () {
                final controller = UserController();

                final result = controller.logout();

                expect(result.errorMessage, ErrorConstants.USER_NOT_LOGGED_IN);
                expect(controller.currentUser, isNull);
            });
        });

        group("deposit()", () {
            test("succeed", () {
                final controller = UserController();
                controller.login("john");

                final result = controller.deposit("100");

                expect(result.errorMessage, "");
                expect(controller.currentUser?.name, "john");
                expect(controller.currentUser?.balance, 100);
            });

            test("succeed increase again", () {
                final controller = UserController();
                controller.login("john");

                final result = controller.deposit("100");
                expect(result.errorMessage, "");

                // add another deposit
                controller.deposit("20");

                expect(controller.currentUser?.name, "john");
                expect(controller.currentUser?.balance, 120);
            });

            test("failed, not logged in", () {
                final controller = UserController();

                final result = controller.deposit("100");

                expect(result.errorMessage, ErrorConstants.USER_NOT_FOUND);
                expect(controller.currentUser, isNull);
            });

            test("failed, wrong format amount", () {
                final controller = UserController();
                controller.login("john");

                final result = controller.deposit("q100");

                expect(result.errorMessage, ErrorConstants.INVALID_AMOUNT);
                expect(controller.currentUser, isNotNull);
            });
        });


        group("withdraw()", () {
            test("succeed", () {
                final controller = UserController();
                controller.login("john");
                controller.deposit("100");

                final result = controller.withdraw("30");

                expect(result.errorMessage, "");
                expect(controller.currentUser?.name, "john");
                expect(controller.currentUser?.balance, 70);
            });

            test("succeed decrease again", () {
                final controller = UserController();
                controller.login("john");
                controller.deposit("200");

                final result = controller.withdraw("100");
                expect(result.errorMessage, "");

                // add another deposit
                controller.withdraw("23");

                expect(controller.currentUser?.name, "john");
                expect(controller.currentUser?.balance, 77);
            });

            test("failed, not logged in", () {
                final controller = UserController();

                final result = controller.withdraw("100");

                expect(result.errorMessage, ErrorConstants.USER_NOT_FOUND);
                expect(controller.currentUser, isNull);
            });

            test("failed, wrong format amount", () {
                final controller = UserController();
                controller.login("john");

                final result = controller.withdraw("q100");

                expect(result.errorMessage, ErrorConstants.INVALID_AMOUNT);
                expect(controller.currentUser, isNotNull);
            });

            test("failed, not enough balance", () {
                final controller = UserController();
                controller.login("john");

                final result = controller.withdraw("100");

                expect(result.errorMessage, ErrorConstants.INVALID_FINAL_BALANCE);
                expect(controller.currentUser?.balance, 0);
            });

            test("failed, not enough balance 2", () {
                final controller = UserController();
                controller.login("john");
                controller.deposit("50");

                final result = controller.withdraw("100");

                expect(result.errorMessage, ErrorConstants.INVALID_FINAL_BALANCE);
                expect(controller.currentUser?.balance, 50);
            });
        });

        group("transfer()", () {
            test("succeed", () {
                final controller = UserController();
                controller.login("john");
                controller.logout();
                controller.login("ema");
                controller.deposit("200");

                controller.transfer("100", "john");

                expect(controller.currentUser?.name, "ema");
                expect(controller.currentUser?.balance, 100);
            });

            test("not enough balance", () {
                final controller = UserController();
                controller.login("john");
                controller.logout();
                controller.login("ema");
                controller.deposit("200");

                controller.transfer("300", "john");

                expect(controller.currentUser?.name, "ema");
                expect(controller.currentUser?.balance, 0);
                expect(controller.currentUser?.debts, isNotEmpty);
                expect(controller.currentUser?.debts?.first?.amount, 100);
            });

            test("not found target user", () {
                final controller = UserController();
                controller.login("john");
                controller.logout();
                controller.login("ema");
                controller.deposit("200");

                controller.transfer("300", "billy");

                expect(controller.currentUser?.name, "ema");
                expect(controller.currentUser?.balance, 200);
            });
        });

        group("edge case", () {
            test("pay debt", () {
                final controller = UserController();
                // create user
                controller.login("john");
                controller.logout();

                // change user to ema
                controller.login("ema");

                // when
                controller.deposit("200");
                controller.transfer("300", "john");

                // then
                expect(controller.currentUser?.name, "ema");
                expect(controller.currentUser?.balance, 0);
                expect(controller.currentUser?.debts?.first?.amount, 100);

                // when deposit to pay the debt
                controller.deposit("150");
                expect(controller.currentUser?.debts, isEmpty);

                // go to john account to see their balance
                controller.logout();
                final result = controller.login("john");
                final generateGreetings = "Hello, John\nReceived \$200 from Ema\nReceived \$100 from Ema\nYour balance is \$300";
                expect(result.data, generateGreetings);
                expect(controller.currentUser?.pendingNotification, isEmpty);
            });

            test("pay debt with debt", () {
                // create user
                final controller = UserController();
                controller.login("john");
                controller.logout();
                controller.login("ema");
                controller.logout();

                // change user to ruben
                controller.login("ruben");

                // when ruben create debt to john
                controller.transfer("300", "john");

                // change user to ema
                controller.logout();
                var result = controller.login("ema");
                var generateGreetings = "Hello, Ema\nYour balance is \$0";
                expect(result.data, generateGreetings);
                expect(controller.currentUser?.pendingNotification, isEmpty);

                // when ema create debt to ruben
                result = controller.transfer("100", "ruben");
                generateGreetings = "Your balance is \$0\nOwed \$100 to Ruben";
                expect(result.data, generateGreetings);

                // change user to ruben
                controller.logout();
                result = controller.login("ruben");
                generateGreetings = "Hello, Ruben\nYour balance is \$0\nOwed \$300 to John\nOwed \$100 from Ema";
                expect(result.data, generateGreetings);
                expect(controller.currentUser?.pendingNotification, isEmpty);

                // change user to ema
                controller.logout();
                result = controller.login("ema");
                generateGreetings = "Hello, Ema\nYour balance is \$0\nOwed \$100 to Ruben";
                expect(result.data, generateGreetings);
                expect(controller.currentUser?.pendingNotification, isEmpty);

                // deposit to pay the debt
                result = controller.deposit("50");
                generateGreetings = "Transferred \$50 to Ruben\nYour balance is \$0\nOwed \$50 to Ruben";
                expect(result.data, generateGreetings);

                // change user to ruben
                controller.logout();
                result = controller.login("ruben");
                generateGreetings = "Hello, Ruben\nReceived \$50 from Ema\nTransferred \$50 to John\nYour balance is \$0\nOwed \$250 to John\nOwed \$50 from Ema";
                expect(result.data, generateGreetings);
                expect(controller.currentUser?.pendingNotification, isEmpty);

                // deposit to pay the debt
                result = controller.deposit("350");
                generateGreetings = "Transferred \$250 to John\nYour balance is \$100";
                expect(result.data, generateGreetings);

                // change user to john
                controller.logout();
                result = controller.login("john");
                generateGreetings = "Hello, John\nReceived \$50 from Ruben\nReceived \$250 from Ruben\nYour balance is \$300";
                expect(result.data, generateGreetings);
                expect(controller.currentUser?.pendingNotification, isEmpty);
            });
        });
    });
}
