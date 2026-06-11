class PatientMedicalDetails {
  int age;
  int height;
  int weight;
  String gender;
  String habbits;
  String workingEnvironment;

  PatientMedicalDetails(
      {required this.age,
      required this.height,
      required this.weight,
      required this.gender,
      required this.habbits,
      required this.workingEnvironment});

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'habbits': habbits,
      'workingEnvironment': workingEnvironment,
    };
  }
}
