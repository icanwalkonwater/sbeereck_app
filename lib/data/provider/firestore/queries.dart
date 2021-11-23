import '../../models.dart';
import '../../providers.dart';

extension FirestoreAccountQuery on FirestoreDataModel {
  CustomerAccount accountById(String id) {
    return accounts.firstWhere((acc) => acc.id == id,
        orElse: () => CustomerAccount.dummy);
  }

  CustomerStat computeAccountStatsForCurrentEvent(String accountId) {
    var quantityDrank = 0.0;
    var totalMoney = 0;
    currentEventTransactions
        .where((element) => element.customerId == accountId)
        .forEach((element) {
      if (element is EventTransactionDrink) {
        quantityDrank += element.quantityReal;
      } else if (element is EventTransactionRecharge) {
        totalMoney += element.amount;
      }
    });

    return CustomerStat(quantityDrank: quantityDrank, totalMoney: totalMoney);
  }

  num computeMoneySpentInDrinkForCurrentEventForAccount(String accountId) {
    return currentEventTransactions
        .where((t) => t.customerId == accountId && t is EventTransactionDrink)
        .map((t) => (t as EventTransactionDrink).priceReal)
        .reduce((a, b) => a + b);
  }
}
