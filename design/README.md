<div align="center">
<img src="../docs/assets/fleexa_letter_logo.svg" alt="Logo" width="120" height="120">
  <br></br>
  <h1>Fleexa UI/UX Design Assets</h1>
  <p><strong>The core design system, wireframes, and visual assets powering the Fleexa IoT Fleet Management ecosystem.</strong></p>
</div>


---

## Directory Architecture

```text
design/
├── assets/
│   ├── colors/
│   │   └── colors.json           (Strict application color definitions)
│   ├── fonts/
│   │   └── font_families.json    (Typography rules and fallbacks)
│   └── icons/
│       └── *.svg                 (Custom iconography exports)
└── wireframes/
    └── wireframes.pdf            (High-fidelity UI screens and user flows)
```

---

## The Color System

The Fleexa application utilizes a modern, deep dark-mode aesthetic. It relies heavily on high-contrast crimson accents to draw attention to critical hardware actions, alerts, and system states.

### Brand Identity
| Swatch | Name | Hex Code | Usage |
| :---: | :--- | :--- | :--- |
| <img src="https://placehold.co/15x15/CC2427/CC2427.png" width="15" height="15"> | **Crimson Red** | `#CC2427` | Charts and data visualization (high visibility) |
| <img src="https://placehold.co/15x15/9E1B32/9E1B32.png" width="15" height="15"> | **Burgundy** | `#9E1B32` | Highlighted text to pop on dark backgrounds |
| <img src="https://placehold.co/15x15/5D0D15/5D0D15.png" width="15" height="15"> | **Dark Maroon** | `#5D0D15` | Primary CTA buttons |
| <img src="https://placehold.co/15x15/511118/511118.png" width="15" height="15"> | **Wine Red** | `#511118` | Switch buttons and toggles |
| <img src="https://placehold.co/15x15/2B0F12/2B0F12.png" width="15" height="15"> | **Dark Burgundy**| `#2B0F12` | Background gradients for device actuator cards |

### Interface Surfaces (Dark Mode)
| Swatch | Name | Hex Code | Usage |
| :---: | :--- | :--- | :--- |
| <img src="https://placehold.co/15x15/111111/111111.png" width="15" height="15"> | **Jet Black** | `#111111` | Primary scaffold and app background |
| <img src="https://placehold.co/15x15/1A1A1A/1A1A1A.png" width="15" height="15"> | **Charcoal Black** | `#1A1A1A` | Primary background for most standard cards |
| <img src="https://placehold.co/15x15/1E1E1E/1E1E1E.png" width="15" height="15"> | **Settings Card** | `#1E1E1E` | Specific settings cards to pop against the background |
| <img src="https://placehold.co/15x15/282828/282828.png" width="15" height="15"> | **Dark Gray** | `#282828` | Icon backgrounds within cards |
| <img src="https://placehold.co/15x15/393939/393939.png" width="15" height="15"> | **Dim Gray** | `#393939` | Inactive navigation icons and borders |

### Typography & Accents
| Swatch | Name | Value | Usage |
| :---: | :--- | :--- | :--- |
| <img src="https://placehold.co/15x15/FFFFFF/FFFFFF.png" width="15" height="15"> | **White** | `#FFFFFF` | Primary headings, active sensor values |
| <img src="https://placehold.co/15x15/D9D9D9/D9D9D9.png" width="15" height="15"> | **Light Gray** | `#D9D9D9` | Secondary body text |
| <img src="https://placehold.co/15x15/8A8A8A/8A8A8A.png" width="15" height="15"> | **Cool Gray** | `#8A8A8A` | Inactive states, hints, tertiary text |
| <img src="https://placehold.co/15x15/CB5E1B/CB5E1B.png" width="15" height="15"> | **Copper Orange** | `#CB5E1B` | Warning states, specific sensor rings |
| <img src="https://placehold.co/15x15/2FC642/2FC642.png" width="15" height="15"> | **Emerald Green** | `#2FC642` | Success states, connection indicators |

> **Note on Opacity:** The system also utilizes specific translucent overlays, primarily `White 10%` for subtle dividers, and `Burgundy 40%` for translucent active backgrounds.

---

## Typography

The application strictly uses the **Rubik** font family. Its geometric yet slightly rounded corners perfectly balance the technical nature of an IoT platform with a modern, user-friendly aesthetic.

* **Primary Font Face:** `Rubik`
* **Hierarchy Weights:**
  * `Regular (400)` - Standard body copy
  * `Medium (500)` - Subtitles and secondary buttons
  * `SemiBold (600)` - Primary buttons and section headers
  * `Bold (700)` - Main numerical readouts and screen titles

*The corresponding `.ttf` files are bundled directly in the Flutter project's frontend assets.*

---

## User Flows & High-Fidelity UI

The complete high-fidelity UI designs can be viewed in the `wireframes/wireframes.pdf` document. This file acts as the primary reference for frontend implementation and includes:

1. **Authentication:** Login, Registration, and Onboarding flows.
2. **System Dashboards:** Main overviews and active fleet status.
3. **Sensor Telemetry:** Detailed historical graphs for Temperature, Gas, and Light.
4. **Hardware Actuators:** Real-time remote control screens for AC units and Smart Door Locks.
5. **Configuration:** User profile management and app settings.