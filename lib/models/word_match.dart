enum WordMatchStatus {
  correct,
  missed,
  wrong,
  pending,
}

class WordMatch {
  final String expectedWord;
  final String? heardWord;
  final WordMatchStatus status;
  final int index;

  WordMatch({
    required this.expectedWord,
    this.heardWord,
    required this.status,
    required this.index,
  });

  WordMatch copyWith({
    String? expectedWord,
    String? heardWord,
    WordMatchStatus? status,
    int? index,
  }) {
    return WordMatch(
      expectedWord: expectedWord ?? this.expectedWord,
      heardWord: heardWord ?? this.heardWord,
      status: status ?? this.status,
      index: index ?? this.index,
    );
  }

  @override
  String toString() {
    return 'WordMatch(expected: $expectedWord, heard: $heardWord, status: $status)';
  }
}