import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/coptic_calendar_service.dart';
import '../../data/services/youversion_service.dart';
import '../../data/models/coptic_day_info.dart';

// Events
abstract class CopticEvent extends Equatable {
  const CopticEvent();
  @override
  List<Object?> get props => [];
}

class LoadCopticData extends CopticEvent {}

// States
abstract class CopticState extends Equatable {
  const CopticState();
  @override
  List<Object?> get props => [];
}

class CopticInitial extends CopticState {}

class CopticLoading extends CopticState {}

class CopticLoaded extends CopticState {
  final CopticDayInfo dayInfo;
  final Map<String, String?> passageTexts;
  const CopticLoaded({required this.dayInfo, this.passageTexts = const {}});
  @override
  List<Object?> get props => [dayInfo, passageTexts];
}

class CopticError extends CopticState {
  final String message;
  const CopticError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class CopticBloc extends Bloc<CopticEvent, CopticState> {
  final YouVersionService? _youVersion;

  CopticBloc({YouVersionService? youVersion})
      : _youVersion = youVersion,
        super(CopticInitial()) {
    on<LoadCopticData>((event, emit) async {
      emit(CopticLoading());
      try {
        final dayInfo = CopticCalendarService.computeToday();
        final texts = <String, String?>{};
        if (_youVersion != null) {
          for (final ref in dayInfo.readings) {
            final text = await _youVersion!.getPassageText(ref);
            if (text != null) {
              texts[ref.displayName] = text;
            }
          }
        }
        emit(CopticLoaded(dayInfo: dayInfo, passageTexts: texts));
      } catch (e) {
        emit(const CopticError('Failed to load Coptic data.'));
      }
    });
  }
}
