# App UI Review Findings

Review of the registration flow UI (onboarding, create account, Sign Up steps, Terms, blocked, Home placeholder) against WCAG 2.2 AA, Material and Apple touch guidance, and the project standards.

- **Date:** 2026-10-07
- **Scope:** `valuex-mobile` at branch `feature/us-001-user-registration-mobile`
- **Status:** In progress under US-110. Onboarding is fixed; the other screens follow one at a time.

## How the review was done

- Read the colour, text, spacing and theme tokens in `lib/core/theme` and every shared and feature widget.
- Computed WCAG contrast ratios for every text and control colour pair. Text needs 4.5:1. Borders and control edges need 3:1.
- Ran Flutter's built-in accessibility checks (Android 48 dp tap target, iOS 44 pt tap target, tap target labels, text contrast) on all 9 screens. The temporary test is deleted.
- Not verified: text clipping at large font sizes (G10). The overflow check cannot see clipped text, so G10 is a likely gap until tested.

## Already passing

- Body text on the page background is 17.9:1.
- White on the brand gradient end colour is 4.71:1.
- Sign Up controls, the back button and the avatar all have a tap area of at least 44 px.
- Registration screens lay out at 2x text size in English and Hindi without overflow.
- Every control tested has a label, except the two onboarding buttons (G16).
- Dividers are decorative and exempt from the 3:1 rule.
- There is no dark theme. The app stays light in system dark mode. Not proposed here.

## Gaps and proposed fixes

Status values: Open, Fixed, Accepted (with reason).

### Colour and contrast

| # | Gap | Measured | Where | Proposed fix | Status |
|---|---|---|---|---|---|
| G1 | Secondary text too light | 4.41:1 on page background, 4.20:1 on input fill | Subtitles, field labels, note card, "coming soon" | Darken `brandMutedText` to `#5B6B82` (4.8 to 5.0:1) | Fixed 2026-10-08 (token) |
| G2 | Placeholder and hint text far too light | 2.26 to 2.38:1 | Input hints, state hint, OTP timer, Terms "last updated" | Darken `brandPlaceholder` until it passes 4.5:1. It will end up close to the muted text colour. | Fixed 2026-10-08 (token) |
| G3 | Error text too light, set at 12 px | 3.49 to 3.76:1 | Inline errors, OTP errors | Change `brandError` to `#C81E1E` (5.1 to 5.7:1) | Fixed 2026-10-08 (token) |
| G4 | Blue link text too light | 3.98 to 4.18:1 | Change number, Resend, Sign in, Retry | Add a darker link text colour `#1F5AE6` (5.1 to 5.3:1). Button fills stay as they are. | In progress: link token added; Mobile and email OTP done, Sign in and Retry follow with their screens |
| G5 | Onboarding colours from Figma fail | Subtitle `#8F8B8B` 3.12:1, Skip text `#5B5BF7` 4.10:1 | Onboarding screens | Subtitle `#6F6B6B`, Skip `#4A4AE0`. Changes Figma colours, needs design sign-off. | Onboarding fixed 2026-10-07 |
| G6 | Field and control edges nearly invisible | Border 1.16:1, field fill against page 1.05:1 (needs 3:1) | Text fields, gender chips, state picker, OTP boxes, cards | Solid 1 px border in `brandControlBorder` `#76839B` (3.4 to 3.8:1), 2 px primary when focused. Visible look change. | In progress: outlined buttons, inputs and OTP boxes done; choices and pickers follow with their screens |
| G7 | White on the primary button has no margin | 4.51:1 | Primary buttons | Optional: darken the blue to `#2559E8` (5.7:1) | Open |
| G8 | Disabled buttons are only 40% opacity, with no hint why | Low contrast | Sign Up, Verify | Dedicated disabled style (see G19) | Open |

### Typography and readability

| # | Gap | Proposed fix | Status |
|---|---|---|---|
| G9 | 12 px is used for important text: errors, OTP countdown, resend status, Terms date. Skip is 13 px. | Use 14 px for errors and helper text. Keep 12 px only for non-essential captions. | In progress: Skip, labels, helper and error text done; remaining screens follow |
| G10 | Onboarding title and subtitle sit in fixed-height boxes (76 and 69 px). Onboarding, splash and Home were not tested at large text sizes. | Remove fixed heights, test at 1.5x and 2x, cap the maximum text scale. | In progress: onboarding done |
| G11 | Type scale has gaps. Link style is copied inline in 5+ places. Only 5 of 15 Material text slots are mapped, so the date picker and snackbars use default fonts. | Add `link`, `caption` and `error` styles, and set the theme font family. | Open |
| G12 | Hindi heading at 28 px uses a 1.36 line height. Devanagari marks may clip. | Check visually, raise heading line height to about 1.5. | Open |

### Touch targets

| # | Gap | Measured | Proposed fix | Status |
|---|---|---|---|---|
| G13 | Onboarding Skip is too small | 64 x 31 | Tap area at least 48 px high. Look stays the same. | Fixed 2026-10-07 |
| G14 | Onboarding back and next pass iOS 44 but fail Android 48 | 45 x 45 | Raise to 48 | Fixed 2026-10-07 |
| G15 | Our minimum is 44, below Material's 48 dp. The back button and all 44 px TextButtons fail Flutter's Android check. | 44 | Raise `minTouchTarget` to 48 and update CODING_STANDARDS 3.4 | In progress: token is 48; OTP links done, remaining 44 px controls follow with their screens |

### Screen reader and keyboard

| # | Gap | Proposed fix | Status |
|---|---|---|---|
| G16 | Onboarding next and back buttons have no label, so VoiceOver and TalkBack users cannot get past onboarding. The page dots have no "page 2 of 4" description. | Add labels and a dots description | Fixed 2026-10-07 |
| G17 | Screen titles are not marked as headings. The loading spinner is not announced. | Mark titles as headers, add a loading label | In progress: onboarding and the shared registration frame done |

### User friendliness

| # | Gap | Proposed fix | Status |
|---|---|---|---|
| G18 | Blocking errors (invalid mobile or email, Aadhaar failure, Sign Up failure) appear in a snackbar that disappears after about 4 seconds and is not tied to a field. | Show errors inline under the field. Keep snackbars for transient network messages. | In progress: Mobile entry and OTP done |
| G19 | The Sign Up button stays dimmed with no explanation of what is missing. | Keep it enabled and show errors on tap, or add a hint line | In progress: Mobile entry and OTP done |
| G20 | Animations ignore the system "reduce motion" setting. | Skip the animated dots and progress bar when it is on | Open |

## Progress by screen

Each screen is shown as a before and after design, approved, then implemented with tests.

| Screen | Status |
|---|---|
| Onboarding | Approved and implemented 2026-10-07 |
| Create Account | Approved and implemented 2026-10-08 |
| Mobile | Approved and implemented 2026-10-08 |
| Mobile OTP and the shared OTP view (Email OTP) | Approved and implemented 2026-10-08 |
| Email entry | Approved and implemented 2026-10-08 |
| Aadhaar, Aadhaar OTP, Sign Up, Terms, Blocked, Home, Splash | Pending |

## Proposed fix order

Each step ends with `flutter analyze` and the tests. The design system doc ([Flutter-Design-System.md](Flutter-Design-System.md)) is updated in the same step.

1. Colour tokens (G1 to G5, G7, G12). One commit fixes most failures at once.
2. Field and control borders (G6).
3. Touch targets (G13 to G15), including raising the standard to 48.
4. Screen reader (G16, G17).
5. Typography and large text (G9 to G11).
6. Errors and disabled state (G8, G18, G19), then reduced motion (G20).
7. Permanent guard: a test that runs the tap target, label and contrast checks on every screen, so new screens must pass.

## Decisions needed

| Decision | Options | Answer |
|---|---|---|
| Change the look for G5 (Figma colours) and G6 (more visible field borders)? | Yes / No / Middle option: 1 px border at exactly 3:1 | G5 approved 2026-10-07; G6 approved with the colour `#76839B` on 2026-10-08 |
| Touch target minimum | 48 (recommended) / keep 44 | 48 approved 2026-10-07 |
| Move blocking errors inline (G18)? | Yes (recommended) / keep snackbars | Pending |

## Evidence

Contrast ratios were computed with the WCAG relative luminance formula. Semi-transparent borders were blended over their background first. Colours checked:

| Pair | Ratio |
|---|---|
| `#0A0D1E` on `#F4F6FF` (body) | 17.88 |
| `#64748B` on `#F4F6FF` (muted) | 4.41 |
| `#64748B` on `#EEF0FF` (muted on input fill) | 4.20 |
| `#94A3B8` on `#EEF0FF` (placeholder) | 2.26 |
| `#2D6BFF` on `#F4F6FF` (link) | 4.18 |
| `#EF4444` on `#F4F6FF` (error) | 3.49 |
| White on `#2D6BFF` (button) | 4.51 |
| White on `#C026D3` (gradient end) | 4.71 |
| `#8F8B8B` on `#F4F6FF` (onboarding subtitle) | 3.12 |
| `#5B5BF7` on `#E9E9FF` (Skip) | 4.10 |
| Input border (12% primary) on `#EEF0FF` | 1.16 |
| Input fill `#EEF0FF` on `#F4F6FF` | 1.05 |

Candidate replacements and their ratios: `#5B6B82` on input fill 4.79; `#1F5AE6` on page background 5.32; `#C81E1E` on page background 5.32; `#6F6B6B` on page background 4.88; `#4A4AE0` on Skip background 5.25; `#5F7BB5` border on input fill 3.72.
