import "dart:io";
import "package:args/args.dart";

import "package:atm/entities/models/user.dart";
import "package:atm/entities/exceptions/result.dart";
import "package:atm/features/user.dart";
import "package:atm/utils/extensions/string.dart";
import "package:atm/utils/constants.dart";

void main(List<String> arguments) {
    final controller = UserController();

    while(true) {
        stdout.write("> ");
        final input = stdin.readLineSync();

        if (input == null || input == "") { continue; }

        final formattedInput = input.toLowerCase();
        final args = formattedInput.split(" ");
        final inputLength = args.length;
        final command = args[0];

        switch(command) {
        case "login":
            if (inputLength != 2) {
                stdout.writeln("${ErrorConstants.WRONG_ARGUMENT}: $command\n");
                continue;
            }

            final name = args[1];
            final result = controller.login(name);
            final data = result.data;
            if (result.errorMessage.isNotEmpty) {
                stdout.writeln(result.errorMessage);
            } else if (data != null && data is String) {
                stdout.writeln(data);
            }
        case "deposit":
            if (inputLength != 2) {
                stdout.writeln("${ErrorConstants.WRONG_ARGUMENT}: $command");
                continue;
            }

            final amount = args[1];
            final result = controller.deposit(amount);
            final data = result.data;
            if (result.errorMessage.isNotEmpty) {
                stdout.writeln(result.errorMessage);
            } else if (data != null && data is String) {
                stdout.writeln(data);
            }
        case "withdraw":
            if (inputLength != 2) {
                stdout.writeln("${ErrorConstants.WRONG_ARGUMENT}: $command");
                continue;
            }

            final amount = args[1];
            final result = controller.withdraw(amount);
            final data = result.data;
            if (result.errorMessage.isNotEmpty) {
                stdout.writeln(result.errorMessage);
            } else if (data != null && data is String) {
                stdout.writeln(data);
            }
        case "transfer":
            if (inputLength != 3) {
                stdout.writeln("${ErrorConstants.WRONG_ARGUMENT}: $command");
                continue;
            }

            final targetUser = args[1];
            final amount = args[2];
            final result = controller.transfer(amount, targetUser);
            final data = result.data;
            if (result.errorMessage.isNotEmpty) {
                stdout.writeln(result.errorMessage);
            } else if (data != null && data is String) {
                stdout.writeln(data);
            }
        case "logout":
            if (inputLength != 1) {
                stdout.writeln("${ErrorConstants.WRONG_ARGUMENT}: $command");
                continue;
            }

            final result = controller.logout();
            final data = result.data;
            if (result.errorMessage.isNotEmpty) {
                stdout.writeln(result.errorMessage);
            } else if (data != null && data is String) {
                stdout.writeln(data);
            }
        case "exit":
            exit(0);
        default:
        stdout.writeln("${ErrorConstants.WRONG_COMMAND}\n");
            continue;
        }

        // print extra space
        stdout.writeln();
    }
}
