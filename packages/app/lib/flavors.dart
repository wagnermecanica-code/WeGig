enum Flavor {
  dev,
  staging,
  prod,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'WeGig DEV';
      case Flavor.staging:
        return 'WeGig STAGING';
      case Flavor.prod:
        return 'WeGig';
    }
  }

}
