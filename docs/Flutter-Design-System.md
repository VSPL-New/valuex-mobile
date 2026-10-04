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
| `brandBackground` | `#F4F6FF` | Page background |
| `brandSurface` | `#FFFFFF` | Cards, outlined buttons, Create Account page |
| `brandSurfaceTint` | `#EEF0FF` | Input fill |
| `brandMuted` | `#E2E8FF` | Light tint of brand blue: `SingleToneButton` fill, progress track |
| `brandForeground` | `#0A0D1E` | Primary text |
| `brandMutedText` | `#64748B` | Secondary text, labels |
| `brandPlaceholder` | `#94A3B8` | Placeholders, hints |
| `brandOnPrimary` | `#FFFFFF` | Text on brand fills |
| `brandPrimary` | `#2D6BFF` | Brand blue, cursor, focus |
| `brandAccent` | `#C026D3` | Brand magenta |
| `brandBorder` | `#2D6BFF` at 12% | Input and card borders |
| `brandBorderFocused` | `#2D6BFF` at 30% | Focused input border |
| `brandOutline` | `#DEDEDE` | Outlined button border |
| `brandDivider` | `#DCE4E8` | Divider lines |
| `brandError` | `#EF4444` | Errors |

Onboarding-only: `onboardingSkipBackground` `#E9E9FF`, `onboardingSkipText` `#5B5BF7`, `onboardingSubtitle` `#8F8B8B`, `onboardingDotActive` `#D708B7`, `onboardingDotInactive` `#0149FD`, `onboardingBackButton` `#E703B2`, `onboardingNextButton` `#0149FD`.

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
| `input` | DM Sans 14 / 20, foreground |
| `bodySecondary` | DM Sans 14 / 20, muted |
| `label` | DM Sans 12, letter spacing 0.6, muted (use uppercase text) |
| `hint` | DM Sans 12, placeholder colour |
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

Figma's 55 and 60 px buttons are normalised to 56. The onboarding Next button keeps its Figma radius of 7.

---

## 3. Assets

- Asset paths live in `AppAssets` (`lib/core/constants/app_assets.dart`). Do not hardcode paths in widgets.
- Icons and illustrations are the **exact files exported from Figma**. Never hand-draw an SVG or edit exported bytes. Figma asset URLs expire in about 7 days, so download and commit them.
- SVG icons render with `flutter_svg`.

### 3.1 Logo — one place to change

- Every screen shows the logo through `BrandLogo` (`lib/shared/widgets/brand_logo.dart`), which reads `AppAssets.logo` = `assets/images/logo.png`.
- **To swap the logo:** replace `assets/images/logo.png` (keep the path). When the designer's transparent logo arrives, also set `BrandLogo`'s default `blendWith` to `null`.
- The current PNG has an opaque white backdrop, so `BrandLogo` multiplies it into the page colour (`blendWith`, default `brandBackground`). On a white surface pass `blendWith: null`.

---

## 4. Components

Shared widgets live in `lib/shared/widgets/`. Reuse them; extract a new shared atom for any generic button, input or icon, even on its first use.

| Widget | Tier | Use |
|---|---|---|
| `BrandGradientButton` | atom | **Primary action.** Brand gradient, 56 high, radius 16, DM Sans 16 bold, glow. |
| `SingleToneButton` | atom | **Secondary action.** Same size, radius and type as the primary, on a light tint of brand blue (`brandMuted`) with `brandForeground` text. |
| `OutlinedIconButton` | atom | **Alternative sign-in or action with a leading icon** (Google, Guest). White, `brandOutline` border, radius 10, DM Sans 16 bold in `brandForeground`. |
| `AppButton` | atom | **Generic utility button** (Retry, dialogs, forms outside the main flow). Solid `brandPrimary` (the gradient's blue end), outlined variant, loading state. |
| `SquareBackButton` | atom | **Canonical back button** (Figma rounded square). Use on every page that goes back. |
| `OnboardingNavButton` | atom | Onboarding next (radius 7) and back (radius 12) controls |
| `BrandLogo` | atom | The logo |
| `AppTextField`, `ErrorView`, `LoadingIndicator` | atoms | Generic building blocks themed from `AppTheme` |

### 4.1 Button rules for new screens

- Use only the widgets above. **Do not create a new button style or a per-screen variant.**
- One primary (`BrandGradientButton`) per screen. A second action next to it uses `SingleToneButton`. Alternative methods use `OutlinedIconButton`. Use `AppButton` only for generic utility actions.
- All buttons are 56 high. Disabled means `onPressed: null` (shown at 40% opacity); do not hide or restyle disabled buttons.
- Button labels use sentence case ("Create an Account", "Sign In"), not UPPERCASE.
- Only `brandPrimary` and `brandAccent` (the two ends of the brand gradient) may be used as button colours.
- Placement: bottom-anchored actions respect the safe-area inset; stacked buttons are separated by `AppSpacing.sm` to `AppSpacing.md`.

Feature widgets: `OnboardingSlide`, `OnboardingDots` (one dot per page), `OnboardingNavButton`, `LabeledDivider`, `MobileNumberField` (+91 prefix, 10 digits).

Inputs inherit `InputDecorationTheme` from `AppTheme` (tint fill, 12 px radius, `brandBorder`, focused `brandBorderFocused`). Do not restyle them per screen.

---

## 5. Layout rules

- Design basis is the 428×926 Figma frame. Scale horizontal artwork with screen width and keep text at fixed sizes.
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
| Tap targets | At least 48×48 dp. Extend the hit area with padding when the visual is smaller (Back 35 px, Skip 64×31). |
| Text scaling | Layouts must work at 200% system font size: no clipping, scrollable pages, no fixed-height text boxes |
| Screen readers | Every interactive element has a semantic label; decorative images are excluded; logo uses the label "JustQlic" |
| Focus and keyboard | Logical focus order; visible focus; inputs use correct `keyboardType` and autofill hints |
| Motion | Respect reduce-motion (splash progress animation, page transitions) |
| State | Never rely on colour alone to show errors or selection |

Contrast of the current colour pairs (calculated):

| Pair | Ratio | Result |
|---|---|---|
| `brandForeground` on `brandBackground` | 17.9 | Pass |
| White on `brandPrimary` | 4.51 | Pass |
| White on `brandAccent` | 4.71 | Pass |
| `brandMutedText` on `brandBackground` | 4.41 | Marginal (just under 4.5) |
| `brandMutedText` on `brandSurfaceTint` | 4.20 | Fail for body text |
| Skip text on `onboardingSkipBackground` | 4.10 | Fail |
| `onboardingSubtitle` on onboarding fade | 3.26 | Fail |
| `brandPlaceholder` on `brandSurfaceTint` | 2.26 | Fail |
| `brandPlaceholder` hint on `brandBackground` | 2.38 | Fail |

These Figma colours need designer sign-off to darken `brandMutedText`, `brandPlaceholder`, `onboardingSubtitle` and `onboardingSkipText` to at least 4.5:1. Until then, treat them as known gaps, not as a pattern to copy.

Known gaps to close before release: tap targets on Back and Skip, fixed-height text boxes on onboarding, missing semantic labels on icon buttons and illustrations, reduce-motion handling.

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
- Use Inter, Outfit, Plus Jakarta Sans, General Sans or Parkinsans.
- Create a back button, input or button style per screen.
- Hand-draw icons or edit exported assets.
- Silently copy a Figma value that conflicts with a token, or silently change a token.

---

## 10. Open items

| Item | Owner |
|---|---|
| Transparent JustQlic logo | Designer |
| Darker colours for the failing contrast pairs | Designer |
| Clean export of the onboarding screen 4 illustration (baked-in status bar) | Designer |
| Terms and consent checkbox on the mobile number page (required by US-001) | Product |
| Role-based `ThemeExtension` and dark theme | Engineering |
| Tap-target, text-scaling and semantics fixes | Engineering |

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

### Approved exceptions

None yet. Add a row here only when the product owner approves decision B in section 6.1.

| Date | Screen | Element | Figma value kept | Approved by |
|---|---|---|---|---|
