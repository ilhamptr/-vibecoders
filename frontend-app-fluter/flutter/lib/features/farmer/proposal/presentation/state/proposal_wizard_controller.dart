import 'package:flutter/foundation.dart';

import '../../../common/farmer_media_service.dart';
import '../../../data/api_farmer_proposal_service.dart';
import '../../../data/farmer_repository.dart';

class ProposalWizardController extends ChangeNotifier {
  ProposalWizardController({
    required this.repository,
    FarmerProposalDetails? initial,
    this.editingId,
  }) : draft = initial?.copy() ?? FarmerProposalDetails();
  final FarmerRepository repository;
  final FarmerProposalDetails draft;
  final String? editingId;
  int step = 0;
  int? returnTo;
  String? error;
  bool busy = false;
  bool submitted = false;
  void changed() {
    error = null;
    notifyListeners();
  }

  bool validate([int? at]) {
    error = switch (at ?? step) {
      0 when draft.landName.trim().isEmpty => 'Isi nama lahan.',
      0 when draft.sppt == null || !FarmerMediaService.isPdf(draft.sppt!) =>
        'Unggah dokumen SPPT dalam format PDF.',
      0
          when draft.address.trim().isEmpty ||
              draft.area <= 0 ||
              !draft.area.isFinite =>
        'Isi alamat lengkap dan luas lahan yang valid.',
      1
          when draft.commodity == null ||
              draft.harvestTons <= 0 ||
              !draft.harvestTons.isFinite ||
              draft.salePrice <= 0 =>
        'Pilih komoditas dan isi estimasi panen serta harga penjualan.',
      2 when draft.total <= 0 || draft.budget.values.any((v) => v < 0) =>
        'Isi rincian kebutuhan modal yang valid.',
      2 when draft.otherCostError != null => draft.otherCostError,
      3 when draft.risks.isEmpty => 'Pilih setidaknya satu risiko lahan.',
      _ => null,
    };
    notifyListeners();
    return error == null;
  }

  void next() {
    if (!validate()) return;
    step = returnTo ?? (step + 1).clamp(0, 4);
    returnTo = null;
    notifyListeners();
  }

  void back() {
    if (returnTo != null) {
      step = returnTo!;
      returnTo = null;
    } else if (step > 0) {
      step--;
    }
    error = null;
    notifyListeners();
  }

  void edit(int target) {
    returnTo = step;
    step = target;
    error = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (busy || submitted) return false;
    for (var i = 0; i < 4; i++) {
      if (!validate(i)) {
        step = i;
        notifyListeners();
        return false;
      }
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (editingId == null) {
        await repository.submit(draft);
      } else {
        await repository.update(editingId!, draft);
      }
      submitted = true;
      return true;
    } on FarmerProposalException catch (e) {
      error = e.message;
      return false;
    } on ArgumentError catch (e) {
      error = '${e.message}';
      return false;
    } catch (_) {
      error = 'Penyimpanan gagal. Silakan coba lagi.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
