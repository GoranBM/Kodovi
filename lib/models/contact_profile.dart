import 'package:uuid/uuid.dart';

class ContactProfile {
  final String pin;
  final bool isSystem; // true = sinkronizirano iz Azure AD, read-only
  String name;
  List<String> phones;
  List<String> emails;
  List<String> web;
  List<Address> addresses;
  List<JobInfo> jobs;

  ContactProfile({
    String? pin,
    this.isSystem = false,
    required this.name,
    required this.phones,
    required this.emails,
    required this.web,
    required this.addresses,
    required this.jobs,
  }) : pin = pin ?? _generatePin();

  static String _generatePin() =>
      const Uuid().v4().replaceAll('-', '').substring(0, 8);

  Map<String, dynamic> toJson() => {
        "pin": pin,
        "isSystem": isSystem,
        "name": name,
        "phones": phones,
        "emails": emails,
        "web": web,
        "addresses": addresses.map((e) => e.toJson()).toList(),
        "jobs": jobs.map((e) => e.toJson()).toList(),
      };

  static ContactProfile fromJson(Map<String, dynamic> json) {
    return ContactProfile(
      pin: json["pin"] as String?,
      isSystem: json["isSystem"] == true,
      name: json["name"] ?? "",
      phones: List<String>.from(json["phones"] ?? []),
      emails: List<String>.from(json["emails"] ?? []),
      web: List<String>.from(json["web"] ?? []),
      addresses: (json["addresses"] as List? ?? [])
          .map((e) => Address.fromJson(e))
          .toList(),
      jobs: (json["jobs"] as List? ?? [])
          .map((e) => JobInfo.fromJson(e))
          .toList(),
    );
  }
}

class Address {
  String street;
  String city;
  String zip;
  String country;

  Address({
    required this.street,
    required this.city,
    required this.zip,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        "street": street,
        "city": city,
        "zip": zip,
        "country": country,
      };

  static Address fromJson(Map<String, dynamic> json) {
    return Address(
      street: json["street"] ?? "",
      city: json["city"] ?? "",
      zip: json["zip"] ?? "",
      country: json["country"] ?? "",
    );
  }
}

class JobInfo {
  String title;
  String department;
  String company;

  JobInfo({
    required this.title,
    required this.department,
    required this.company,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "department": department,
        "company": company,
      };

  static JobInfo fromJson(Map<String, dynamic> json) {
    return JobInfo(
      title: json["title"] ?? "",
      department: json["department"] ?? "",
      company: json["company"] ?? "",
    );
  }
}
