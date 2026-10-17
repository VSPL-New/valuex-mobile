# ValueX Brand Colours

Source: `lib/core/theme/colors.dart` (tokens) and `lib/core/theme/gradients.dart` (gradient). Use the tokens, never raw hex values. Colours with a percentage are the hex at that opacity.

Several brand tokens are darker than the Figma Make values so text stays readable (for example `brandMutedText` is #5B6B82, not Make's #64748B). Contrast checks are in `test/core/theme/contrast_test.dart`; add a row there when you add a colour pair.

## Brand

| Token | Hex | Purpose |
|---|---|---|
| `brandPrimary` | #135CFF | Main brand blue: gradient start, focus border, loading spinner, selected edges, icons |
| `brandAccent` | #C026D3 | Brand magenta: gradient end, badge fills, second plan accent |
| `brandLink` | #1F5AE6 | Text links, selected chip text, prices and AI notice text (darker blue so text reaches 4.5:1) |
| `brandInstruction` | #135CFF | Instruction text on the page |
| Brand gradient | #135CFF to #C026D3 (top-left to bottom-right) | Primary buttons and the progress bar; the only gradient in the app |

## Surfaces

| Token | Hex | Purpose |
|---|---|---|
| `brandBackground` | #F4F6FF | Page background on every screen |
| `brandSurface` | #FFFFFF | Cards, chips, dialogs |
| `brandSurfaceTint` | #EEF0FF | Input fill, selected chip fill, AI notice |
| `brandMuted` | #E2E8FF | Muted fills |

## Text

| Token | Hex | Purpose |
|---|---|---|
| `brandForeground` | #0A0D1E | Body text, headings, prices |
| `brandMutedText` | #5B6B82 | Secondary text, labels, helper text |
| `brandPlaceholder` | #5F6D83 | Input placeholder text |
| `brandOnPrimary` | #FFFFFF | Text and icons on gradient, blue and magenta fills |

## Lines and status

| Token | Hex | Purpose |
|---|---|---|
| `brandBorder` | #135CFF at 12% | Light card edges, header and footer dividers, breakdown card |
| `brandBorderFocused` | #135CFF at 30% | Soft focused edges, AI notice border |
| `brandOutline` | #DEDEDE | Neutral outlines |
| `brandControlBorder` | #76839B | Edges of inputs, chips and plan cards (3:1 contrast) |
| `brandDivider` | #DCE4E8 | Divider lines in lists and cards |
| `brandError` | #C81E1E | Error text, error borders and icons |
| `brandSuccess` | #16A34A | Tick badges, selected condition chip edge |
| `brandSuccessText` | #166534 | Selected condition text, discount amount |
| `brandSuccessTint` | #E8F6ED | Selected condition chip fill |

## Sell flow

| Token | Hex | Purpose |
|---|---|---|
| `sellAiCardStart` / `sellAiCardEnd` | #EDE9FF / #FBEAFF | Photo step "Let AI do the work" card gradient |
| `sellSparkle` | #F59E0B | Amber sparkle and price note clock icon |
| `sellAddTile` | #135CFF at 8% | Add-photo tile fill |
| `sellNoteTint` | #FEF7EB | Price note card fill |
| `sellNoteBorder` | #F59E0B at 20% | Price note card border |

## Onboarding only (Figma: Just Qlic)

| Token | Hex | Purpose |
|---|---|---|
| `onboardingSkipBackground` | #E9E9FF | Skip pill background |
| `onboardingSkipText` | #4A4AE0 | Skip text |
| `onboardingSubtitle` | #6F6B6B | Subtitle text |
| `onboardingDotActive` | #D708B7 | Current page dot |
| `onboardingDotInactive` | #0149FD | Other page dots |
| `onboardingBackButton` | #E703B2 | Back arrow button |
| `onboardingNextButton` | #0149FD | Next arrow button |
