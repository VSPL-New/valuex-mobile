# JustQlic Mobile — Flutter Design System

Single reference for UI work in `valuex-mobile`. Follow it for every new screen. If a Figma frame conflicts with this document, follow the protocol in section 6.1: this document wins by default, but the product owner is notified and must approve before anything is applied.

---

## 1. Sources of truth and precedence

| Source | Used for |
|---|---|
| **Figma Make app** (`tzrpUwfrR0SYeyKkv1p0co`) | Branding and look and feel: colour tokens (`src/styles/theme.css`), fonts, radii, component styling. React, converted to Flutter equivalents. |
| **Figma design file** "Just-Qlic--Copy-MyVersion" (`D1BtJ1lsMVRBLtUPBv1UIr`) | Per-page layout and exact measurements (428×926 frame). |

Rules:
- When a page exists in both, take layout from the design file and tokens (colours, fonts, gradient) from Make.
- When a page exists only in Make, follow Make.
- Conflicts between a Figma frame and this document are handled with the protocol in section 6.1, never by guessing.
- The product name is **JustQlic**. Make's "ValueX" text and wordmark are replaced by the JustQlic logo and name. Package and bundle IDs stay `valuex_mobile` / `com.valuex.valuex_mobile`.

---

## 2. Tokens

All tokens live in `lib/core/theme/`. **Never use literal colours, font names, radii or standard spacings in widgets.** Screen-specific Figma pixel offsets (e.g. an illustration position) may stay as private constants in that screen.

### 2.1 Colours — `AppColors` (`colors.dart`)

Global tokens are prefixed `brand`. Screen-specific tokens use the screen name (`onboarding*`).

| Token | Value | Use |
|---|---|---|
| `brandBackground` | `#F4F6FF` | **Page background of every screen** (very light blue, from Make's `--background`) |
| `brandSurface` | `#FFFFFF` | Cards and outlined buttons only. Never a full-page background. |
| `brandSurfaceTint` | `#EEF0FF` | Input fill |
| `brandMuted` | `#E2E8FF` | Light tint of brand blue: `SingleToneButton` fill, progress track |
| `brandForeground` | `#0A0D1E` | Primary text |
| `brandMutedText` | `#5B6B82` | Secondary text, field labels, helper text, icons beside helper text |
| `brandPlaceholder` | `#5F6D83` | Placeholder text inside inputs (not for helper text or icons; use `brandMutedText`) |
| `brandOnPrimary` | `#FFFFFF` | Text on brand fills |
| `brandPrimary` | `#2D6BFF` | Brand blue, cursor, focus |
| `brandAccent` | `#C026D3` | Brand magenta |
| `brandLink` | `#1F5AE6` | Text links (Resend code, Change number). `brandPrimary` is only 4.2:1 on the page, this is 5.3:1 |
| `brandBorder` | `#2D6BFF` at 12% | Input and card borders |
| `brandBorderFocused` | `#2D6BFF` at 30% | Decorative only; inputs now focus with a 2 px `brandPrimary` border |
| `brandOutline` | `#DEDEDE` | Decorative outlines only (no longer used for controls) |
| `brandControlBorder` | `#76839B` | **Edge of every control that must be seen to be found** (outlined buttons now; inputs, choices and pickers as their screens are reviewed). 3.4–3.8:1 on white, page and input fill |
| `brandDivider` | `#DCE4E8` | Divider lines |
| `brandError` | `#C81E1E` | Error text, icons and borders (5.1 to 5.7:1) |

Onboarding-only: `onboardingSkipBackground` `#E9E9FF`, `onboardingSkipText` `#4A4AE0`, `onboardingSubtitle` `#6F6B6B`, `onboardingDotActive` `#D708B7`, `onboardingDotInactive` `#0149FD`, `onboardingBackButton` `#E703B2`, `onboardingNextButton` `#0149FD`. The Skip text and subtitle colours are darker than Figma's `#5B5BF7` and `#8F8B8B` to reach 4.5:1 (approved 2026-10-07).

### 2.2 Gradient — `AppGradients.brand` (`gradients.dart`)

**One gradient app-wide:** blue `#2D6BFF` to magenta `#C026D3`, top-left to bottom-right. Use it for every gradient fill (primary buttons, progress bars). Do not add other gradients. The white fade over onboarding illustrations is a transparency fade, not a colour gradient.

### 2.3 Typography — `AppFonts`, `AppTextStyles` (`text_styles.dart`)

| Family | Use | Bundled weights |
|---|---|---|
| **Poppins** (`AppFonts.heading`) | Headings | 400, 500, 600, 700 |
| **DM Sans** (`AppFonts.body`) | Body, inputs, labels, hints, buttons, divider label, onboarding copy | 400, 500, 600, 700 |

Two families only. Do not add a third.

| Style | Spec |
|---|---|
| `heading1` | Poppins 28 / 38, w700 (onboarding titles) |
| `heading2` | Poppins 24 / 1.5, w700 (page titles) |
| `body` | DM Sans 16 / 1.5 |
| `input` | DM Sans 16 / 24, foreground (typed text and placeholder) |
| `bodySecondary` | DM Sans 14 / 20, muted |
| `label` | DM Sans 14 / 20 medium, letter spacing 0.4, muted (field labels) |
| `hint` | DM Sans 14 / 20, muted (helper text, timers; 12 px is for non-essential captions only) |
| `error` | DM Sans 14 / 20 medium, `brandError` (message under a field, always with an icon) |
| `link` | DM Sans 16 / 24 semi-bold, `brandLink` (tappable text; give it a 48 dp tap area) |
| `button` | DM Sans 16, w700, white; on `OutlinedIconButton` the colour is `brandForeground` |
| `dividerLabel` | DM Sans 14, w500, spacing -0.28 |

Inter, Outfit, Plus Jakarta Sans, General Sans and Parkinsans are not used.

### 2.4 Spacing, radius, sizes — `spacing.dart`

| Token | Value |
|---|---|
| `AppSpacing` xs / sm / md / lg / xl | 4 / 8 / 16 / 24 / 32 |
| `AppRadius` sm / md / lg / xl | 6 / 10 / 12 / 16 |
| `AppSizes.buttonMedium` | 56 (every button and text input) |
| `AppSizes.backButton` | 35.1 (Figma back button) |
| `AppSizes.minTouchTarget` | 48 (smallest tap area of any control; Material's 48 dp, which also covers iOS's 44 pt) |

Figma's 55 and 60 px buttons are normalised to 56. The onboarding Next button keeps its Figma radius of 7.

---

## 3. Assets

- Asset paths live in `AppAssets` (`lib/core/constants/app_assets.dart`). Do not hardcode paths in widgets.
- Icons and illustrations are the **exact files exported from Figma**. Never hand-draw an SVG or edit exported bytes. Figma asset URLs expire in about 7 days, so download and commit them.
- SVG icons render with `flutter_svg`.

### 3.1 Logo — one place to change

- Every screen shows the logo through `BrandLogo` (`lib/core/widgets/brand_logo.dart`), which reads `AppAssets.logo` = `assets/images/logo.png`.
- **To swap the logo:** replace `assets/images/logo.png` (keep the path). When the designer's transparent logo arrives, also set `BrandLogo`'s default `blendWith` to `null`.
- The current PNG has an opaque white backdrop, so `BrandLogo` multiplies it into the page colour (`blendWith`, default `brandBackground`). On a white surface pass `blendWith: null`.

---

## 4. Components

Shared widgets live in `lib/core/widgets/`. Reuse them; extract a new shared atom for any generic button, input or icon, even on its first use.

| Widget | Tier | Use |
|---|---|---|
| `BrandGradientButton` | atom | **Primary action.** Brand gradient, 56 high, radius 16, DM Sans 16 bold, glow. |
| `SingleToneButton` | atom | **Secondary action.** Same size, radius and type as the primary, on a light tint of brand blue (`brandMuted`) with `brandForeground` text. |
| `OutlinedIconButton` | atom | **Alternative sign-in or action with a leading icon** (Google, Guest). White, `brandControlBorder` border, radius 10, DM Sans 16 bold in `brandForeground`. The label wraps to a second line at large text. |
| `AppButton` | atom | **Generic utility button** (Retry, dialogs, forms outside the main flow). Solid `brandPrimary` (the gradient's blue end), outlined variant, loading state. |
| `SquareBackButton` | atom | **Canonical back button** (Figma rounded square, 48×48 tap area). Use on every page that goes back. |
| `OnboardingNavButton` | atom | Onboarding next (radius 7) and back (radius 12) controls. 45 px drawing inside a 48 dp tap area; requires a `label` for screen readers. |
| `BrandLogo` | atom | The logo |
| `AppTextField`, `ErrorView`, `LoadingIndicator` | atoms | Generic building blocks themed from `AppTheme` |
| `OtpInput` | molecule | Six-digit code drawn as boxes over one real text field (paste, autofill, backspace). Boxes use the input tint and `brandControlBorder`; the current box and errors use 2 px `brandPrimary` and `brandError` borders. Boxes grow with the text size. Screen readers hear the typed digits. Give it a new `key` to empty it. |
| `FieldError` | atom | **The one way to show a form error:** error icon plus `error` text in a live region. Use it under every field and OTP input. |
| `ProtectedScreen` | utility | Wraps a screen that must block screenshots (Aadhaar now; payment, escrow and bank details later). Reference counted through `ScreenProtectionService`. |

Auth feature widgets (`lib/features/auth/presentation/widgets/`): `AuthFormScaffold` (back, logo, title, scrolling content, fixed bottom actions; used by every registration step), `OtpVerificationView`, `AadhaarNoteCard` (tint card with `brandAccent` icon), `GenderSelector` (three equal choices, stacked one per line at large text; selected = `brandPrimary` 2 px border on `brandSurfaceTint`; unselected `brandControlBorder`; takes an `errorText`), `DateOfBirthField` (typed DD/MM/YYYY plus a calendar icon), `StatePickerField` (field-style row opening a list sheet), `AvatarImage` and the avatar picker sheet.

### 4.1 Button rules for new screens

- Use only the widgets above. **Do not create a new button style or a per-screen variant.**
- One primary (`BrandGradientButton`) per screen. A second action next to it uses `SingleToneButton`. Alternative methods use `OutlinedIconButton`. Use `AppButton` only for generic utility actions.
- All buttons are at least 56 high and grow when the label wraps at large text (never truncate a label). Disabled means `onPressed: null` (shown at 40% opacity); do not hide or restyle disabled buttons.
- Button labels use sentence case ("Create an Account", "Sign In"), not UPPERCASE.
- Only `brandPrimary` and `brandAccent` (the two ends of the brand gradient) may be used as button colours.
- Placement: bottom-anchored actions respect the safe-area inset; stacked buttons are separated by `AppSpacing.sm` to `AppSpacing.md`.

Feature widgets: `OnboardingSlide`, `OnboardingDots` (one dot per page), `OnboardingNavButton`, `LabeledDivider`, `MobileNumberField` (+91 prefix, 10 digits).

Inputs inherit `InputDecorationTheme` from `AppTheme`: tint fill, 12 px radius, 1 px `brandControlBorder`, 2 px `brandPrimary` when focused, 2 px `brandError` on error. Do not restyle them per screen.

**Form error rule:** show an error under the field with `FieldError` (14 px `error` style, an icon, live region), not in a snackbar, and keep it until the user edits the field. Scroll it into view at large text. For a plain `TextField` pass `InputDecoration(error: FieldError(text: ...))`; the theme then draws the red 2 px border (see `SignupEmailScreen`). Snackbars are for passing messages only. A submit button stays enabled; tapping it with invalid input shows the error (see `SignupMobileScreen`). Each field also announces its label to screen readers. When a form can fail below the fold, scroll its first message into view with `Scrollable.ensureVisible` (see `AadhaarScreen`).

---

## 5. Layout rules

- Design basis is the 428×926 Figma frame. Scale horizontal artwork with screen width and keep text at fixed sizes.
- **Every screen has the `brandBackground` (`#F4F6FF`) full-screen background.** It comes from `scaffoldBackgroundColor` in `AppTheme`, so do not set a page colour on a `Scaffold`, and do not use white or any other full-page colour (including Figma frames drawn on white). Fades and overlays over artwork must end in `brandBackground`.
- Images with an opaque white backdrop (logo, illustrations) are multiplied into `brandBackground` until transparent assets are supplied.
- Anchor bottom content (buttons, CTAs) to the bottom using Figma offsets, and always add the system safe-area inset.
- Respect `SafeArea` at the top; do not draw under the status bar unless the design requires it.
- Page side padding is 24 (`AppSpacing.lg`) on Make-based pages and 21.5 on the Figma Create Account page.
- Do not use fixed heights for text that can wrap. Fixed-height text boxes (currently onboarding title 76 and subtitle 69) must be replaced before large text sizes are supported (see 7).

---

## 6. Figma to Flutter workflow

1. Read the target node with the Figma tools and load the `nova-figma-to-code` skill first. Read the Make source for branding.
2. Map colours, fonts, radii, spacing and component styles to the tokens and components in this document. If anything conflicts or has no token, stop and follow section 6.1 before writing code for it.
3. Reuse existing components. Classify every new element (atom, molecule, organism, template, page).
4. Download exact assets with `curl`; register paths in `AppAssets`.
5. Record the node in `.figma/mapping.json` (path, tier, content hash). On a revisit, check for drift and ask before overwriting.
6. Run `dart format`, `flutter analyze` and `flutter test`. Verify on the Android emulator and iOS simulator with screenshots.
7. Branch from `main` (`feature/<kebab-case>`), open a PR to `main`. List every conflict found and the decision taken in the PR description.

### 6.1 Conflicting design tokens (mandatory protocol)

Applies to every new screen or change taken from the Figma design file or the Figma Make app.

**What counts as a conflict:** a Figma frame uses a colour, gradient, font family, font size or weight, radius, spacing, control height, shadow, icon style, button style, back button or other component that differs from this document, or uses a value for which this document has no token.

**Rule:** this document is the source of truth. The default resolution is always to implement the screen with the token or component defined here, not with the Figma value.

**Process (do not skip steps):**
1. **Detect.** Compare every colour, font, radius, size, spacing and component in the frame with sections 2 and 4 before writing code.
2. **Notify.** Send the product owner a conflict report (template below) for all conflicts found in the screen, in one message. Do not write code for the conflicting elements yet; non-conflicting parts of the screen can proceed.
3. **Wait for approval.** Nothing is applied or updated until the product owner replies with a decision per conflict. Silence is not approval.
4. **Apply** exactly the approved decision (below).
5. **Record.** Add the decision to the decision log (section 11) and, if a token changed, update the tables in this document in the same PR.

**Decisions the owner can choose per conflict:**

| Decision | Meaning |
|---|---|
| **A. Use the document token** (default, recommended) | Implement with the existing token or component. The Figma value is ignored. |
| **B. Approve an exception** | Keep the Figma value on that screen only. It is logged as an exception and does not become precedent. |
| **C. Change the design system** | Update the token or component here (value, new token or removal), then update every usage in the app, so the whole app stays consistent. |

Changing, adding or removing a token or shared component (decision C) is a design-system change: it always needs explicit approval, must be done in the same PR as the document update, and must keep one gradient, two font families and the button set from section 4.

**Conflict report template:**

| Screen / node | Element | Figma value | Document token or component | Proposed resolution | Visual or accessibility impact |
|---|---|---|---|---|---|
| e.g. Sign In, `3:286` | Primary button | 60 px high, radius 12, uppercase | `BrandGradientButton` (56, radius 16, sentence case) | A. Use document token | Button is 4 px shorter |

**Not a conflict (proceed without asking):** layout, positions, copy, illustrations and anything that already maps exactly to a token or component here.

---

## 7. Accessibility

Target: **WCAG 2.2 AA** for all screens in the first release.

| Area | Rule |
|---|---|
| Text contrast | Body text at least 4.5:1; large text (24 px, or 18.7 px bold) at least 3:1; UI components and icons at least 3:1 |
| Tap targets | At least `AppSizes.minTouchTarget` (48×48 dp, CODING_STANDARDS 3.4). When the visual is smaller (Back 35 px, Skip pill 31 px high, onboarding arrows 45 px) keep the drawing and extend the tap area: a `SizedBox` of the minimum size with an opaque `GestureDetector`, plus `Semantics(button: true, label: ..., onTap: ...)`. |
| Text scaling | Layouts must work at 200% system font size: no clipping, scrollable pages, no fixed-height text boxes (use a minimum height and let text grow). Text laid over an illustration gets a solid backing when the text is enlarged (see `OnboardingSlide`). |
| Screen readers | Every interactive element has a semantic label (icon-only buttons must pass a `label`); screen titles are marked `Semantics(header: true)`; page indicators say "Page x of y"; decorative images are excluded; logo uses the label "JustQlic" |
| Focus and keyboard | Logical focus order; visible focus; inputs use correct `keyboardType` and autofill hints |
| Motion | Respect reduce-motion: wrap every animation duration in `motionDuration(context, ...)` (`core/utils/motion.dart`); never pass a zero duration to `animateToPage` or `nextPage`, jump instead. The splash bar is shown full, onboarding changes page at once. |
| State | Never rely on colour alone to show errors or selection |

Contrast of the current colour pairs (calculated):

| Pair | Ratio | Result |
|---|---|---|
| `brandForeground` on `brandBackground` | 17.9 | Pass |
| White on `brandPrimary` | 4.51 | Pass |
| White on `brandAccent` | 4.71 | Pass |
| `brandMutedText` `#5B6B82` on `brandBackground` | 5.03 | Pass (was 4.41) |
| `brandMutedText` on `brandSurfaceTint` | 4.79 | Pass (was 4.20) |
| `brandError` `#C81E1E` on `brandBackground` / white / input fill | 5.32 / 5.74 / 5.07 | Pass (was 3.49) |
| Skip text `#4A4AE0` on `onboardingSkipBackground` | 5.25 | Pass (was 4.10) |
| `onboardingSubtitle` `#6F6B6B` on `brandBackground` | 4.88 | Pass (was 3.12) |
| `brandPlaceholder` `#5F6D83` on `brandSurfaceTint` / `brandBackground` | 4.63 / 4.87 | Pass (was 2.26) |

All text colours reach 4.5:1 (links use `brandLink`; do not use `brandPrimary` for text). `test/core/theme/contrast_test.dart` holds the contrast checks; add a row there for every new colour pair.

New registration controls (gender choices, state picker, calendar icon, show/hide, resend and change links, avatar tiles, switch) are 44 dp or larger. The inline "Terms and Conditions" link inside a sentence is smaller; it is the only exception.

**Enforced by tests (US-110):** `test/all_screens_accessibility_test.dart` runs Flutter's tap target (Android 48 dp, iOS 44 pt), label and text contrast guidelines on every screen; `test/screen_headings_test.dart` checks headings; `test/reduce_motion_test.dart` checks reduce motion. **Add every new screen to the first two.** A screen that fails them does not merge.

**New screen checklist:** tokens only; 48 dp tap areas; every control labelled; title and section titles marked as headings; errors under the field with `FieldError`, submit buttons enabled with validation on tap, the first message scrolled into view; text laid out at 200% in English and Hindi; animations through `motionDuration`; a row in `contrast_test.dart` for any new colour pair; strings in both ARB files.

---

## 8. Dark mode

**Current state:** light only. Widgets read static colours from `AppColors`. Make's `.dark` block is the default shadcn palette, not branded, and the Figma design file has no dark frames.

**Target architecture (build now, ship dark later):**
1. Define colours by **role** (background, surface, foreground, mutedText, primary, border and so on), not by hue. The `brand*` names already map to roles.
2. Expose them through a `ThemeExtension` (`BrandColors`) with a light and a dark instance, plus a `context.colors` accessor. Widgets stop reading `AppColors` constants directly.
3. Build `AppTheme.lightTheme` and `AppTheme.darkTheme`; set `themeMode: ThemeMode.system`.
4. Keep one gradient and one logo; supply dark variants of the logo and illustrations through `AppAssets` (the current logo's white backdrop will not work on dark).
5. Add golden tests for key screens in light and dark.

**Release recommendation:** ship **light mode with accessibility first, and dark mode in the release after**, but do step 1 to 3 (the role-based architecture) now.
- Dark needs design work that does not exist: dark frames, dark logo and illustration variants, and a branded dark palette that meets contrast.
- Accessibility is required at launch and applies to light mode anyway; dark mode is not.
- Doing both together doubles design review and QA across every screen during the highest-churn period.
- Retrofitting role-based colour later across all screens is the expensive part, so it is done now while the app has few screens.

---

## 9. Do and don't

Do:
- Use tokens, `AppAssets`, `BrandLogo` and shared widgets.
- Use the Figma rounded-square back button.
- Add semantics to every new interactive element.
- Report every Figma conflict with this document and wait for approval before applying or changing a token (section 6.1).

Don't:
- Hardcode colours, font names, radii, spacings or asset paths.
- Add a second gradient.
- Set a page background on a `Scaffold` or use a white or other full-page colour.
- Use Inter, Outfit, Plus Jakarta Sans, General Sans or Parkinsans.
- Create a back button, input or button style per screen.
- Show a form error only in a snackbar, or disable a submit button without saying why.
- Hand-draw icons or edit exported assets.
- Silently copy a Figma value that conflicts with a token, or silently change a token.

---

## 10. Open items

| Item | Owner |
|---|---|
| Transparent JustQlic logo | Designer |
| Transparent Create Account illustration (faint edge lines show on `brandBackground` today) | Designer |
| Confirm the darker colours chosen in US-110 (muted text, placeholder, error, link, onboarding, control border) and update Figma | Designer |
| Clean export of the onboarding screen 4 illustration (baked-in status bar) | Designer |
| Native-speaker review of the Hindi strings in `lib/l10n/app_hi.arb` | Product |
| Final avatar artwork (placeholders drawn from icons today; US-003) | Designer |
| Figma frames for the Sign Up form, gender choices, date field, state picker, avatar picker and OTP boxes (built from tokens without a design) | Designer |
| Role-based `ThemeExtension` and dark theme | Engineering |
| Page transitions between routes do not yet respect reduce motion (GoRouter default transitions) | Engineering |

---

## 11. Decision log

Decisions taken so far. Add a row for every approved conflict resolution (section 6.1).

| Date | Screen or area | Conflict | Decision |
|---|---|---|---|
| 2026-10-04 | Gradients | Make auth screens and Figma Create Account used different gradients | **One gradient app-wide:** `AppGradients.brand` (blue to magenta) |
| 2026-10-04 | Primary and secondary buttons | Figma Create Account used 60 px, radius 12, Plus Jakarta uppercase buttons | `BrandGradientButton` (primary) and `SingleToneButton` (secondary), 56 px, DM Sans bold |
| 2026-10-04 | Back button | Figma rounded square vs Make arrow plus text link | `SquareBackButton` everywhere |
| 2026-10-04 | Fonts | Make: Outfit and Plus Jakarta Sans; Figma: Poppins and General Sans | **Poppins** (headings) and **DM Sans** (everything else) only |
| 2026-10-04 | Brand name and logo | Make shows a "ValueX" wordmark | JustQlic logo and name through `BrandLogo` |
| 2026-10-04 | Button colours | Separate colour per screen | Only `brandPrimary` and `brandAccent` (the gradient's ends) |
| 2026-10-04 | Page background | Splash, mobile entry and Make's app shell use `#F4F6FF`; Figma Create Account and onboarding frames are white | `brandBackground` `#F4F6FF` on **all** screens; onboarding fade ends in `brandBackground` |

| 2026-10-06 | OTP boxes, gender choices, date of birth field, state picker, avatar picker, Aadhaar note card, development banner | No Figma design | Built from existing tokens only (no new colour, font or radius) and approved to build; **screenshots still to be reviewed by the product owner** |
| 2026-10-06 | Avatars | Final artwork not available | Placeholder avatars drawn from Material icons on brand-tinted circles; male-looking `avatar-01..04`, female-looking `05..08`, neutral `09..12`; ids unchanged when artwork arrives |
| 2026-10-06 | Hindi text | DM Sans has no Devanagari glyphs | `AppFonts.bodyFallback` uses Poppins, which has Devanagari; no new font |
| 2026-10-06 | Back button size | Figma 35 px against the 44 dp standard | **Approved: enlarge.** `SquareBackButton` has a 44×44 tap area around the unchanged 35 px visual (content below moves down about 9 px) |

| 2026-10-07 | Onboarding colours | Figma subtitle `#8F8B8B` (3.1:1) and Skip text `#5B5BF7` (4.1:1) fail contrast | **Approved: darken** to `#6F6B6B` (4.9:1) and `#4A4AE0` (5.3:1) |
| 2026-10-07 | Touch targets | 44 dp minimum is below Material's 48 dp | **Approved: 48 dp** (`AppSizes.minTouchTarget`); CODING_STANDARDS 3.4 updated; back button tap area grows from 44 to 48 |
| 2026-10-07 | Onboarding Skip, Next and Back | Drawings of 31 and 45 px are below 48 dp | **Approved:** drawing unchanged, tap area 48 dp; Skip text 14 px medium |
| 2026-10-07 | Onboarding at 200% text | Fixed-height text boxes clipped the copy | **Approved:** boxes grow with the text and the copy gets a solid backing over the illustration when text is enlarged |

| 2026-10-08 | Create Account outlined buttons | Border `#DEDEDE` was 1.25:1 against white and the page | **Approved:** new `brandControlBorder` `#76839B` (3.4 to 3.8:1) |
| 2026-10-08 | Shared buttons at large text | Fixed 56 px height cut the Google and Guest labels at 200% | **Approved:** buttons keep a 56 dp minimum and grow; labels wrap instead of being truncated |

| 2026-10-08 | Secondary, placeholder and error colours | `#64748B` (4.2:1), `#94A3B8` (2.3:1) and `#EF4444` (3.5:1) fail contrast | **Approved:** `brandMutedText` `#5B6B82`, `brandPlaceholder` `#5F6D83`, `brandError` `#C81E1E` |
| 2026-10-08 | Input look and text sizes | Input edge 1.2:1; 12 px helper and label text; 14 px typed text | **Approved:** inputs use `brandControlBorder` with a 2 px focus and error border; `label` and `hint` 14 px; `input` 16 px |
| 2026-10-08 | Mobile entry behaviour | Send OTP was disabled with no reason; errors went to a snackbar | **Approved:** Send OTP stays enabled and shows an inline error under the field; server errors also show inline |

| 2026-10-08 | Mobile and email OTP | Box edge 1.2:1; verify dimmed without a reason; links 4.2:1 and 44 dp; digits clipped at 200%; typed digits not announced; old digits left after Resend | **Approved:** `brandControlBorder` edges, Verify stays enabled and asks for six digits, `brandLink` text and 48 dp links, boxes grow with text, digits announced, boxes empty after Resend |

| 2026-10-08 | Email entry | Same gaps as mobile entry | **Approved:** same pattern: inline `FieldError`, Send OTP stays enabled, field label announced |

| 2026-10-08 | Aadhaar and development Aadhaar OTP | Snackbar errors, dimmed Verify, 44 dp controls, unlabeled field | **Approved:** same form pattern as mobile entry; consent shows its own message with a red checkbox; the form scrolls to its messages; the consent copy keeps "ValueX" until legal confirms the brand name |

| 2026-10-08 | Sign Up | Submit dimmed with no reason; messages only for typed-in invalid values; unlabeled fields and switch; faint edges on choices and pickers; 44 dp controls; gender words broken at 200% | **Applied from the approved patterns:** Submit stays enabled and shows a message under every missing or invalid field, scrolling to the first; fields and the terms switch are labelled; `brandControlBorder` edges; 48 dp; gender choices stack at large text; server errors show under the form |
| 2026-10-08 | Terms, Account unavailable, Home, Splash | Plain titles; 44 dp close button; 12 px splash label; fixed-height blocked page | **Applied:** titles and Terms sections are headings; 48 dp close button; 14 px splash label; blocked page scrolls at large text |
| 2026-10-08 | Reduce motion | Animations ignored the system setting | **Applied:** `motionDuration` helper; splash bar static, onboarding jumps, dots and scroll-to-message do not animate |

### Approved exceptions

None yet. Add a row here only when the product owner approves decision B in section 6.1.

| Date | Screen | Element | Figma value kept | Approved by |
|---|---|---|---|---|
