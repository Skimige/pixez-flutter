import 'package:mobx/mobx.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/models/illust_persist.dart';
part 'history_store.g.dart';

class HistoryStore = _HistoryStoreBase with _$HistoryStore;

abstract class _HistoryStoreBase with Store {
  IllustPersistProvider illustPersistProvider = IllustPersistProvider();
  ObservableList<IllustPersist> data = ObservableList();
  @action
  fetch() async {
    await illustPersistProvider.open();
    final result = await illustPersistProvider.getAllAccount();
    data.clear();
    data.addAll(result);
  }

  @action
  insert(Illusts illust) async {
    await illustPersistProvider.open();
    await illustPersistProvider.insert(IllustPersist()
      ..time = DateTime.now().millisecondsSinceEpoch
      ..userId = illust.user.id
      ..pictureUrl = illust.imageUrls.squareMedium
      ..illustId = illust.id);
    await fetch();
  }

  @action
  delete(int id) async {
    await illustPersistProvider.open();
    await illustPersistProvider.delete(id);
    await fetch();
  }

  deleteAll() async {
    await illustPersistProvider.open();
    await illustPersistProvider.deleteAll();
    await fetch();
  }
}
