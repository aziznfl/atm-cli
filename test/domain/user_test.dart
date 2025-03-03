import "package:test/test.dart";

import "package:atm/core/configs.dart";
import "package:atm/domains/usecase/user.dart";
import "package:atm/utils/extensions/list.dart";

void main() {
    group("UserUseCase Tests", () {
        group("addNewUser()", () {
            test("succeed", () {
                // given
                final useCase = UserUseCase();

                // when
                final user = useCase.addNewUser("john");

                // then
                expect(user?.name, "john");
                expect(user?.balance, 0);
            });

            test("failed", () {
                // given
                final useCase = UserUseCase();

                // when
                final user = useCase.addNewUser("");

                // then
                expect(user, isNull);
            });
        });

        group("getUser()", () {
            test("found", () {
                // given
                final data = UserUseCase();
                data.addNewUser("john");

                // when
                final user = data.getUser("john");

                // then
                expect(user, isNotNull);
                expect(user?.name, "john");
            });

            test("not found", () {
                // given
                final data = UserUseCase();

                // when
                final user = data.getUser("john");

                // then
                expect(user, isNull);
            });
        });

        group("receivables()", () {
            test("no borrowers available", () {
                final useCase = UserUseCase();
                final roben = useCase.addNewUser("roben")!;

                // when
                final receivables = useCase.receivables(roben);

                // then
                expect(receivables.length, 0);
            });

            test("show borrowers", () {
                // given
                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final ema = useCase.addNewUser("ema")!;
                final roben = useCase.addNewUser("roben")!;

                // when
                useCase.transfer(john, roben, 30);
                useCase.transfer(john, roben, 25);
                var receivables = useCase.receivables(roben);

                // then
                expect(receivables.length, 1);
                expect(receivables.last.user, john);
                expect(receivables.last.amount, 55);

                // when
                useCase.transfer(ema, roben, 25);
                receivables = useCase.receivables(roben);

                // then
                expect(receivables.length, 2);
                expect(receivables.first.user, john);
                expect(receivables.first.amount, 55);
                expect(receivables.last.user, ema);
                expect(receivables.last.amount, 25);
            });
        });

        group("increaseBalance()", () {
            test("increase from zero succeed", () {
                // given
                final useCase = UserUseCase();
                final user = useCase.addNewUser("john")!;

                // when
                final action = useCase.increaseBalance(user, 100);

                // then
                expect(action, []);
                expect(user.name, "john");
                expect(user.balance, 100);
            });

            test("increase succeed", () {
                // given
                final useCase = UserUseCase();
                final user = useCase.addNewUser("john")!;
                useCase.increaseBalance(user, 20);

                // when
                final action = useCase.increaseBalance(user, 100);

                // then
                expect(action, []);

                expect(user.name, "john");
                expect(user.balance, 120);
            });

            group("_payDebts()", () {
                test("pay full the debt", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 100);
                    useCase.increaseBalance(john, 150);

                    // then
                    expect(john.balance, 50);
                    expect(john.debts, isEmpty);
                    expect(roben.balance, 100);
                });

                test("pay full the debt", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 100);
                    useCase.increaseBalance(john, 70);

                    // then
                    expect(john.balance, 0);
                    expect(john.debts.first.amount, 30);
                    expect(roben.balance, 70);
                });

                test("paid debt to multiple user", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final roben = useCase.addNewUser("roben")!;
                    final ema = useCase.addNewUser("ema")!;

                    // when
                    useCase.transfer(john, roben, 100);
                    useCase.transfer(john, ema, 50);
                    useCase.increaseBalance(john, 120);

                    // then
                    expect(john.balance, 0);
                    expect(john.debts.length, 1);
                    expect(john.debts.first.user, ema);
                    expect(john.debts.first.amount, 30);
                    expect(roben.balance, 100);
                    expect(ema.balance, 20);
                });

                test("add balance zero due to not increase balance", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 100);
                    useCase.increaseBalance(john, 0);

                    // then
                    expect(john.balance, 0);
                    expect(john.debts.first.amount, 100);
                    expect(roben.balance, 0);
                });

                test("stacking debt with full payment", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final ema = useCase.addNewUser("ema")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 100);
                    useCase.transfer(ema, john, 100);
                    useCase.increaseBalance(ema, 100);

                    // then
                    expect(john.balance, 0);
                    expect(ema.balance, 0);
                    expect(roben.balance, 100);
                });

                test("stacking debt with extra payment", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final ema = useCase.addNewUser("ema")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 80);
                    useCase.transfer(ema, john, 100);

                    useCase.increaseBalance(ema, 150);

                    // then
                    expect(john.balance, 20);
                    expect(john.debts, isEmpty);
                    expect(ema.balance, 50);
                    expect(ema.debts, isEmpty);
                    expect(roben.balance, 80);
                    expect(roben.debts, isEmpty);
                });

                test("stacking debt with half payment", () {
                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final ema = useCase.addNewUser("ema")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 80);
                    useCase.transfer(ema, john, 100);

                    useCase.increaseBalance(ema, 50);

                    // then
                    expect(john.balance, 0);
                    expect(john.debts.first.user, roben);
                    expect(john.debts.first.amount, 30);
                    expect(ema.balance, 0);
                    expect(ema.debts.first.user, john);
                    expect(ema.debts.first.amount, 50);
                    expect(roben.balance, 50);
                    expect(roben.debts, isEmpty);
                });

                test("stacking debt auto paid debt is off", () {
                    Config.IS_AUTO_PAID_DEBT = false;

                    final useCase = UserUseCase();
                    final john = useCase.addNewUser("john")!;
                    final ema = useCase.addNewUser("ema")!;
                    final roben = useCase.addNewUser("roben")!;

                    // when
                    useCase.transfer(john, roben, 100);
                    useCase.transfer(ema, john, 80);
                    useCase.increaseBalance(ema, 50);

                    // then
                    expect(john.balance, 50);
                    expect(ema.balance, 0);
                    expect(roben.balance, 0);
                });
            });
        });

        group("decreaseBalance", () {

            test("decrease succeed", () {
                // given
                final useCase = UserUseCase();
                final user = useCase.addNewUser("john")!;
                useCase.increaseBalance(user, 100);

                // when
                final action = useCase.decreaseBalance(user, 5);

                // then
                expect(action, true);

                expect(user.name, "john");
                expect(user.balance, 95);
            });

            test("decrease failed when user not have enough balance", () {
                // given
                final useCase = UserUseCase();
                final user = useCase.addNewUser("john")!;

                // when
                final action = useCase.decreaseBalance(user, 1);

                // then
                expect(action, false);

                expect(user.name, "john");
                expect(user.balance, 0);
            });
        });

        group("transfer()", () {
            test("with empty balance", () {
                // given
                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final ema = useCase.addNewUser("ema")!;

                // when
                useCase.transfer(john, ema, 20);

                // then
                expect(john.debts.first.user, ema);
                expect(john.debts.first.amount, 20);
            });

            test("enough balance", () {
                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final roben = useCase.addNewUser("roben")!;

                // when
                useCase.increaseBalance(john, 100);
                useCase.transfer(john, roben, 25);

                // given
                expect(john.balance, 75);
                expect(john.debts, isEmpty);
                expect(roben.balance, 25);
                expect(roben.pendingNotification.first.user, john);
                expect(roben.pendingNotification.first.amount, 25);
            });

            test("half balance", () {
                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final roben = useCase.addNewUser("roben")!;

                // when
                useCase.increaseBalance(john, 10);
                useCase.transfer(john, roben, 25);

                // given
                expect(john.balance, 0);
                expect(john.debts.last.user, roben);
                expect(john.debts.last.amount, 15);
                expect(roben.balance, 10);
                expect(roben.pendingNotification.first.user, john);
                expect(roben.pendingNotification.first.amount, 10);
            });

            test("invalid amount", () {
                // given
                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final ema = useCase.addNewUser("ema")!;

                // when
                final action = useCase.transfer(john, ema, -20);

                // then
                expect(action, -1);
                expect(john.balance, 0);
                expect(john.debts, isEmpty);
                expect(ema.balance, 0);
                expect(ema.debts, isEmpty);
                expect(ema.pendingNotification, isEmpty);
            });

            test("increase debt", () {
                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final ema = useCase.addNewUser("ema")!;
                final roben = useCase.addNewUser("roben")!;

                useCase.transfer(john, roben, 30);

                final johnDebts = john.debts;
                expect(johnDebts.length, 1);
                expect(johnDebts.last.amount, 30);

                useCase.transfer(john, roben, 25);

                expect(johnDebts.length, 1);
                expect(johnDebts.last.amount, 55);

                useCase.transfer(john, ema, 73);

                expect(johnDebts.length, 2);
                expect(johnDebts.first.user, roben);
                expect(johnDebts.first.amount, 55);
                expect(johnDebts.last.user, ema);
                expect(johnDebts.last.amount, 73);
            });

            test("pay lender debt 1", () {
                Config.IS_AUTO_PAID_DEBT = true;

                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final ema = useCase.addNewUser("ema")!;
                final roben = useCase.addNewUser("roben")!;

                // when
                var transferred = useCase.transfer(john, roben, 30);
                expect(transferred, 0);

                // deposit the balance to make transfer succeed (not debt)
                useCase.increaseBalance(ema, 100);
                transferred = useCase.transfer(ema, john, 50);
                expect(transferred, 50);

                // check john account"s
                expect(john.balance, 20);
                expect(john.debts, isEmpty);
                expect(john.pendingNotification.length, 2);
                expect(john.pendingNotification.first.user, ema);
                expect(john.pendingNotification.first.amount, 50);
                expect(john.pendingNotification.last.user, roben);
                expect(john.pendingNotification.last.amount, -30);

                // check ema account"s
                expect(ema.balance, 50);
                expect(ema.debts, isEmpty);
                expect(ema.pendingNotification, isEmpty);

                // check roben account"s
                expect(roben.balance, 30);
                expect(roben.debts, isEmpty);
                expect(roben.pendingNotification.first.user, john);
                expect(roben.pendingNotification.first.amount, 30);
            });

            test("pay lender debt 2", () {
                Config.IS_AUTO_PAID_DEBT = true;

                final useCase = UserUseCase();
                final john = useCase.addNewUser("john")!;
                final ema = useCase.addNewUser("ema")!;
                final roben = useCase.addNewUser("roben")!;

                // when
                var transferred = useCase.transfer(john, roben, 80);
                expect(transferred, 0);

                // deposit the balance to make transfer succeed (not debt)
                useCase.increaseBalance(ema, 100);
                transferred = useCase.transfer(ema, john, 35);
                expect(transferred, 35);

                // check john account"s
                expect(john.balance, 0);
                expect(john.debts.first.user, roben);
                expect(john.debts.first.amount, 45);
                expect(john.pendingNotification.length, 2);
                expect(john.pendingNotification.first.user, ema);
                expect(john.pendingNotification.first.amount, 35);
                expect(john.pendingNotification.last.user, roben);
                expect(john.pendingNotification.last.amount, -35);

                // check ema account"s
                expect(ema.balance, 65);
                expect(ema.debts, isEmpty);
                expect(ema.pendingNotification, isEmpty);

                // check roben account"s
                expect(roben.balance, 35);
                expect(roben.debts, isEmpty);
                expect(roben.pendingNotification.length, 1);
                expect(roben.pendingNotification.first.user, john);
                expect(roben.pendingNotification.first.amount, 35);
            });
        });
    });
}
