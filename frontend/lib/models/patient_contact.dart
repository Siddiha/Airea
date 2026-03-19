class PatientContact {
  String relationship;
  String contactNumber;

  PatientContact({required this.relationship, required this.contactNumber});

  Map<String, dynamic> toJson() {
    return {
      'relationship': relationship,
      'contactNumber': contactNumber,
    };
  }
}
