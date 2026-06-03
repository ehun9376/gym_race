enum ImageName {
  logo,
  logoBlack,
  logoVertical,
  tabBarHome,
  tabBarOrder,
  tabBarProfile,
  mapMark,
  mapPing,
  mapCircle,
  imgCar,
  imagPsersonal,
  imgAvatarEdit,
  imgStar,
  customerService,
}

extension ImageNameExtension on ImageName {
  String get path {
    switch (this) {
      case ImageName.logo:
        return "logo/igo-logo.png";
      case ImageName.logoVertical:
        return "logo/igo-logo-vertical.png";
      case ImageName.logoBlack:
        return "logo/igo-logo-black.png";
      case ImageName.tabBarHome:
        return "bottom_tab_bar/tabler_home-filled.png";
      case ImageName.tabBarOrder:
        return "bottom_tab_bar/lets-icons_order-fill.png";
      case ImageName.tabBarProfile:
        return "bottom_tab_bar/iconamoon_profile-fill.png";
      case ImageName.mapMark:
        return "map/map_mark.png";
      case ImageName.mapPing:
        return "map/map_ping.png";
      case ImageName.mapCircle:
        return "map/map_circle.png";
      case ImageName.imgCar:
        return "img/img_ic_car.png";
      case ImageName.imagPsersonal:
        return "img/img_ic_personal.png";
      case ImageName.imgAvatarEdit:
        return "img/img_avatar_edit.png";
      case ImageName.imgStar:
        return "img/img_star.png";
      case ImageName.customerService:
        return "img/tdesign_service.png";
    }
  }
}
