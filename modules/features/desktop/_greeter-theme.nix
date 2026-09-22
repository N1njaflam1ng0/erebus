# NOT a flake-parts module: import-tree's default filter is
# `andNot (hasInfix "/_") (hasSuffix ".nix")`, so anything with a `_` path
# component is skipped. That is what lets this be a plain `import`-ed function
# shared between a nixosModule (sddm.nix) and a homeModule's package (_lock.nix).
#
# The greeter and the lockscreen run the same theme QML, so they must read the
# same config -- this attrset is the one copy of it.
{ background }:
let
  # Srcery, lifted slot-for-slot from assets/quickshell/config/Colors.qml so the
  # greeter and the shell cannot drift apart without someone noticing.
  hardBlack    = "#0E0D0C";
  black        = "#121110";
  gray1        = "#1C1B19";
  gray3        = "#312F2C";
  brightBlack  = "#917E6B";
  white        = "#C5B088";
  brightWhite  = "#FCE8C3";
  magenta      = "#E02C6D";  # Colors.qml `accent`
  brightRed    = "#F75341";  # Colors.qml `error`
in {
  Background = background;
  BackgroundColor = hardBlack;
  DimBackgroundColor = hardBlack;
  # Just enough to knock the gold back so the form panel stays the brighter half.
  DimBackground = "0.15";
  CropBackground = "true";

  HeaderText = "erebus";
  Font = "CaskaydiaCove Nerd Font";
  HourFormat = "HH:mm";
  DateFormat = "dddd d MMMM";
  # The shell is square-cornered (Style.bar.radius: 0).
  RoundCorners = "0";

  # Split layout: the form panel takes the left third, the seal gets the rest.
  # (With FormPosition=center the opaque panel sits straight on top of the
  # background and the seal never shows.)
  FormPosition = "left";
  BackgroundHorizontalAlignment = "center";
  HaveFormBackground = "true";
  PartialBlur = "false";
  FormBackgroundColor = gray1;

  HeaderTextColor = brightWhite;
  TimeTextColor = brightWhite;
  DateTextColor = white;

  LoginFieldBackgroundColor = gray3;
  PasswordFieldBackgroundColor = gray3;
  LoginFieldTextColor = brightWhite;
  PasswordFieldTextColor = brightWhite;
  PlaceholderTextColor = brightBlack;
  UserIconColor = white;
  PasswordIconColor = white;

  LoginButtonBackgroundColor = magenta;
  LoginButtonTextColor = black;
  WarningColor = brightRed;

  SystemButtonsIconsColor = brightBlack;
  SessionButtonTextColor = brightBlack;
  VirtualKeyboardButtonTextColor = brightBlack;

  DropdownBackgroundColor = gray1;
  DropdownTextColor = white;
  DropdownSelectedBackgroundColor = gray3;

  HighlightBackgroundColor = gray3;
  HighlightTextColor = brightWhite;
  HighlightBorderColor = gray3;

  HoverUserIconColor = magenta;
  HoverPasswordIconColor = magenta;
  HoverSystemButtonsIconsColor = magenta;
  HoverSessionButtonTextColor = magenta;
  HoverVirtualKeyboardButtonTextColor = magenta;

  HideVirtualKeyboard = "true";
  ForceLastUser = "true";
  PasswordFocus = "true";
}
