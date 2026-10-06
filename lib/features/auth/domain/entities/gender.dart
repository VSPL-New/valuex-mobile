enum Gender {
  male('MALE'),
  female('FEMALE'),
  others('OTHERS');

  final String apiValue;

  const Gender(this.apiValue);
}
