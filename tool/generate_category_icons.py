"""Generate the bundled icon catalog from the approved taxonomy and curated families."""

import argparse
import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TAXONOMY = ROOT.parent / "Documents/Category_Taxonomy_CSVs/ValueX_JustQlic_Master_Category_Taxonomy_v1.0.csv"
OUTPUT = ROOT / "lib/core/theme/category_icon_catalog.g.dart"

# Exact names, never substring matching: headphones must not become phones, for example.
FAMILIES = {
    "devices_rounded": "Mobiles & Tablets|Electronic|Electronics",
    "computer_rounded": "Computers & IT|Desktops",
    "live_tv_rounded": "TV, Audio & Home Entertainment|Televisions",
    "photo_camera_rounded": "Cameras & Photography|Cameras",
    "sports_esports_rounded": "Gaming|Consoles|Gaming Accessories",
    "kitchen_rounded": "Large Appliances|Refrigerators",
    "blender_rounded": "Small & Home Appliances|Food Preparation",
    "chair_rounded": "Furniture|Living Room",
    "home_rounded": "Home Decor & Furnishings|Real Estate|Homes|Homes & Residences",
    "restaurant_rounded": "Kitchen & Dining|Cutlery & Tools",
    "handyman_rounded": "Home Improvement & Tools|Hand Tools|Hardware",
    "yard_rounded": "Garden & Outdoor|Gardening",
    "checkroom_rounded": "Men's Fashion|Women's Fashion|Fashion|Topwear|Bottomwear|Ethnic & Occasion|Ethnic Wear|Western Wear",
    "child_care_rounded": "Kids & Baby Clothing|Baby Clothing|Boys Clothing|Girls Clothing|Maternity Wear",
    "hiking_rounded": "Footwear|Men Footwear|Women Footwear|Kids Footwear|Outdoor Recreation",
    "luggage_rounded": "Bags, Wallets & Luggage|Luggage",
    "watch_rounded": "Watches, Jewellery & Fashion Accessories|Watches|Wearables",
    "spa_rounded": "Beauty & Personal Care|Skin Care",
    "stroller_rounded": "Baby Gear & Nursery|Mobility|Travel & Safety",
    "toys_rounded": "Toys & Games|Toys|Collectible Toys",
    "menu_book_rounded": "Books, Stationery & Education|Books",
    "sports_soccer_rounded": "Sports, Fitness & Outdoor|Sports|Team Sports",
    "music_note_rounded": "Musical Instruments & Pro Audio|Musical Instruments|String Instruments|Wind Instruments",
    "directions_car_rounded": "Cars|Passenger Cars|Vehicles|Car Parts",
    "two_wheeler_rounded": "Motorcycles & Scooters|Motorcycles|Bike Parts",
    "agriculture_rounded": "Commercial & Agricultural Vehicles|Agricultural Vehicles|Agricultural Equipment",
    "car_repair_rounded": "Vehicle Parts & Accessories|Vehicle Accessories",
    "pedal_bike_rounded": "Bicycles & Micro-Mobility|Bicycles",
    "business_center_rounded": "Office & Business Equipment|Office Machines",
    "precision_manufacturing_rounded": "Industrial & Commercial Equipment|Manufacturing Equipment",
    "medical_services_rounded": "Health & Medical Equipment|Therapy & Wellness Devices",
    "museum_rounded": "Art, Antiques & Collectibles|Antiques",
    "palette_rounded": "Arts, Crafts & Hobby Supplies|Art|Painting & Drawing|Art Supplies",
    "celebration_rounded": "Religious, Festive & Party|Festival Decor|Party & Event",
    "local_grocery_store_rounded": "Packaged Grocery & Consumables (Optional)|Dry & Packaged Food",
    "interests_rounded": "Other|Miscellaneous|Collectibles|Hobby Equipment",
    "smartphone_rounded": "Mobile Phones|Mobiles",
    "tablet_mac_rounded": "Tablets & E-readers|Tablets",
    "cable_rounded": "Mobile Accessories",
    "laptop_mac_rounded": "Laptops",
    "memory_rounded": "Computer Components",
    "monitor_rounded": "Monitors",
    "keyboard_rounded": "Peripherals",
    "print_rounded": "Printers & Scanners",
    "router_rounded": "Networking",
    "storage_rounded": "External Storage",
    "video_camera_front_rounded": "Projectors",
    "cast_rounded": "Streaming & Media",
    "speaker_rounded": "Speakers|Home Audio",
    "headphones_rounded": "Personal Audio",
    "camera_rounded": "Lenses",
    "camera_enhance_rounded": "Photography Accessories",
    "flight_rounded": "Drones",
    "videogame_asset_rounded": "Games",
    "local_laundry_service_rounded": "Washing & Laundry|Dishwashers",
    "ac_unit_rounded": "Air Conditioning",
    "microwave_rounded": "Cooking Appliances",
    "home_work_rounded": "Home Appliances",
    "water_drop_rounded": "Water & Power",
    "bed_rounded": "Bedroom|Sleep & Lounge",
    "table_restaurant_rounded": "Dining",
    "desk_rounded": "Study & Office Furniture",
    "child_friendly_rounded": "Kids Furniture",
    "deck_rounded": "Outdoor Furniture|Outdoor Living",
    "imagesearch_roller_rounded": "Home Decor",
    "curtains_rounded": "Furnishings",
    "light_rounded": "Lighting",
    "shelves": "Storage & Organization|Storage",
    "soup_kitchen_rounded": "Cookware",
    "bakery_dining_rounded": "Bakeware",
    "local_dining_rounded": "Tableware",
    "wine_bar_rounded": "Glassware & Barware",
    "power_rounded": "Electrical",
    "plumbing_rounded": "Plumbing & Bathroom",
    "construction_rounded": "Power Tools|Power & Workshop",
    "grass_rounded": "Lawn Equipment",
    "backpack_rounded": "Backpacks",
    "shopping_bag_rounded": "Handbags",
    "account_balance_wallet_rounded": "Wallets & Small Leather Goods",
    "diamond_rounded": "Fashion Jewellery|Fine Jewellery",
    "category_rounded": "Accessories",
    "sanitizer_rounded": "Fragrance",
    "content_cut_rounded": "Grooming Appliances|Hair Care|Sewing & Textile Crafts",
    "brush_rounded": "Makeup|DIY & Crafts",
    "baby_changing_station_rounded": "Feeding",
    "crib_rounded": "Nursery",
    "extension_rounded": "Board Games & Puzzles",
    "school_rounded": "Academic Books",
    "edit_note_rounded": "Stationery",
    "sports_cricket_rounded": "Cricket",
    "fitness_center_rounded": "Fitness Equipment",
    "sports_tennis_rounded": "Racquet Sports",
    "self_improvement_rounded": "Yoga & Wellness",
    "piano_rounded": "Keyboards & Pianos",
    "album_rounded": "Percussion",
    "mic_rounded": "Pro Audio",
    "moped_rounded": "Mopeds|Scooters",
    "local_shipping_rounded": "Commercial Vehicles|Material Handling",
    "electric_scooter_rounded": "Electric Mobility",
    "phone_in_talk_rounded": "Communication",
    "point_of_sale_rounded": "POS & Retail Equipment",
    "security_rounded": "Security & Access",
    "restaurant_menu_rounded": "Food & Hospitality Equipment",
    "storefront_rounded": "Shop & Display",
    "accessible_rounded": "Mobility Aids",
    "monitor_heart_rounded": "Monitoring Devices",
    "air_rounded": "Respiratory Equipment",
    "set_meal_rounded": "Aquarium Supplies",
    "pets_rounded": "Pet Supplies|Dog Supplies|Cat Supplies|Bird & Small Pet Supplies|Pet Food & Treats",
    "temple_hindu_rounded": "Pooja & Religious",
    "cleaning_services_rounded": "Household Consumables",
    "apartment_rounded": "Commercial & Workspaces|Shared & Managed Living",
    "landscape_rounded": "Land & Plots",
    "holiday_village_rounded": "New Developments",
}

# Give visually different products their own glyph, while variants share their family.
LEAVES = {
    "smartphone_rounded": "Smartphones|Rugged Phones",
    "dialpad_rounded": "Feature Phones",
    "devices_fold_rounded": "Foldable Phones",
    "tablet_android_rounded": "Android Tablets|Windows Tablets",
    "tablet_mac_rounded": "iPads|Graphics Tablets",
    "auto_stories_rounded": "E-readers",
    "watch_rounded": "Smartwatches",
    "fitness_center_rounded": "Fitness Bands|Dumbbells|Barbells|Weight Plates",
    "trip_origin_rounded": "Smart Rings",
    "phone_android_rounded": "Cases & Covers|Screen Protectors",
    "power_rounded": "Chargers & Adapters|Power Supplies",
    "cable_rounded": "Cables",
    "battery_charging_full_rounded": "Power Banks|Camera Batteries & Chargers",
    "dock_rounded": "Holders & Stands|Docking Stations|Console Stands & Docks",
    "edit_rounded": "Styluses|Pens & Pencils|Drawing Tools",
    "sd_card_rounded": "Memory Cards",
    "camera_rounded": "Mobile Camera Lenses|Filters & Adapters",
    "developer_board_rounded": "Motherboards|Graphics Cards (GPU)|Expansion Cards",
    "memory_rounded": "Processors (CPU)|RAM / Memory",
    "storage_rounded": "Internal SSDs|Internal HDDs",
    "desktop_windows_rounded": "Computer Cases",
    "keyboard_rounded": "Keyboards",
    "mouse_rounded": "Mice & Trackpads",
    "videocam_rounded": "Webcams|Camcorders",
    "speaker_rounded": "Computer Speakers|Subwoofers",
    "mic_rounded": "Microphones",
    "usb_rounded": "USB Hubs|USB Flash Drives",
    "scanner_rounded": "Scanners",
    "earbuds_rounded": "TWS Earbuds|IEMs / Earphones",
    "headphones_rounded": "Wireless Headphones|Wired Headphones|Neckbands|Gaming Headsets",
    "speaker_group_rounded": "Home Theatre Systems",
    "surround_sound_rounded": "Soundbars|AV Receivers|Stereo Amplifiers",
    "camera_enhance_rounded": "Gimbals & Stabilizers|Tripods & Monopods",
    "flash_on_rounded": "Flashes & Speedlights",
    "camera_alt_rounded": "Camera Bags & Cases",
    "sports_esports_rounded": "Controllers & Gamepads",
    "sports_motorsports_rounded": "Racing Wheels & Pedals",
    "view_in_ar_rounded": "VR Headsets",
    "coffee_maker_rounded": "Coffee Makers",
    "iron_rounded": "Irons & Garment Steamers",
    "content_cut_rounded": "Sewing Machines",
    "air_rounded": "Fans|Air Coolers|Air Purifiers|Dehumidifiers|Cooling & Fans",
    "solar_power_rounded": "Solar Panels",
    "battery_charging_full_outlined": "Inverters|Home UPS Systems",
    "water_drop_rounded": "Water Purifiers",
    "water_rounded": "Geysers / Water Heaters",
    "chair_rounded": "Sofas|Recliners|Accent Chairs",
    "table_restaurant_rounded": "Coffee Tables|Dining Tables|Outdoor Tables|Bedside Tables",
    "chair_alt_rounded": "Dining Chairs|Bar Stools|Office Chairs|Outdoor Chairs",
    "bed_rounded": "Beds|Mattresses|Kids Beds",
    "door_sliding_rounded": "Wardrobes",
    "shelves": "Shoe Racks|Bookcases|Filing Cabinets|Shelves|Multipurpose Racks",
    "desk_rounded": "Study Desks|Office Desks|Study Tables",
    "inventory_2_rounded": "Toy Storage|Storage Boxes|Closet Organizers",
    "watch_later_rounded": "Clocks",
    "light_rounded": "Studio Lights|Table Lamps|Floor Lamps|Ceiling Lights|Chandeliers|Decorative Lights",
    "curtains_rounded": "Curtains",
    "dry_cleaning_rounded": "Bedsheets|Blankets & Comforters|Bath Linen|Table Linen",
    "house_rounded": "Independent Homes|Villas|Studio Homes",
    "apartment_rounded": "Apartments & Condos|Duplexes & Penthouses|Floor Residences",
    "folder_rounded": "Files & Folders",
    "calculate_rounded": "Calculators|Scientific Calculators",
    "sports_basketball_rounded": "Basketball",
    "sports_volleyball_rounded": "Volleyball",
    "sports_hockey_rounded": "Hockey",
    "pool_rounded": "Swimming Gear",
    "skateboarding_rounded": "Skates & Skateboards",
    "forest_rounded": "Camping Gear",
    "directions_bike_rounded": "Exercise Bikes",
    "directions_run_rounded": "Treadmills|Ellipticals",
    "thermostat_rounded": "Thermometers",
    "local_printshop_rounded": "Receipt Printers|Label Printers",
    "qr_code_scanner_rounded": "Barcode Scanners",
    "videocam_outlined": "CCTV Cameras|Baby Monitors",
    "fingerprint_rounded": "Biometric Attendance Devices",
    "payments_rounded": "Coins",
    "local_post_office_rounded": "Stamps",
    "style_rounded": "Trading Cards|Card Games",
    "image_rounded": "Wall Art & Paintings|Photo Frames|Paintings|Prints & Posters|Photography Prints",
    "cookie_rounded": "Snacks & Biscuits|Chocolates & Candies",
    "coffee_rounded": "Electric Kettles|Tea & Coffee",
}

# "Accessories" belongs to three unrelated roots in the taxonomy.
SCOPED_GROUPS = {
    ("Watches, Jewellery & Fashion Accessories", "Accessories"): "watch_rounded",
    ("Musical Instruments & Pro Audio", "Accessories"): "music_note_rounded",
    ("Bicycles & Micro-Mobility", "Accessories"): "pedal_bike_rounded",
}

HOME_ALIASES = {
    "electronics": "devices_rounded", "laptops": "laptop_mac_rounded",
    "mobiles": "smartphone_rounded", "cameras": "photo_camera_rounded",
    "vehicles": "directions_car_rounded", "furniture": "chair_rounded",
    "fashion": "checkroom_rounded", "appliances": "home_work_rounded",
    "books": "menu_book_rounded", "sports": "sports_soccer_rounded",
    "toys": "toys_rounded", "music": "music_note_rounded",
}


def expand(families):
    result = {}
    for icon, labels in families.items():
        for label in labels.split("|"):
            if label in result:
                raise ValueError(f"Duplicate icon assignment: {label}")
            result[label] = icon
    return result


def generate():
    families, leaves = expand(FAMILIES), expand(LEAVES)
    with TAXONOMY.open(encoding="utf-8-sig", newline="") as source:
        rows = list(csv.DictReader(source))
    codes, names = dict(HOME_ALIASES), dict(families)
    def normalized(value):
        # Matches backend TaxonomyCodes.normalize.
        return re.sub(r"[^A-Z0-9]+", "_", value.upper()).strip("_")
    for row in rows:
        root, group, leaf, code = (row[column] for column in (
            "L1 Category", "L2 Category", "L3 Category", "Category Code"))
        if root not in families or group not in families:
            raise ValueError(f"Unmapped taxonomy family: {root} / {group}")
        if code in codes:
            raise ValueError(f"Duplicate category code: {code}")
        family = SCOPED_GROUPS.get((root, group), families[group])
        codes[code] = leaves.get(leaf, family)
        codes[f"L1-{normalized(root)}"] = families[root]
        codes[f"L2-{normalized(root)}-{normalized(group)}"] = family
    names.update(leaves)
    # Ambiguous leaf names are deliberately not guessed; real leaves use stable codes.
    output = [
        "// Generated by tool/generate_category_icons.py. Do not edit.",
        "// Source: ValueX_JustQlic_Master_Category_Taxonomy_v1.0.csv.",
        "import 'package:flutter/material.dart';", "",
    ]
    for name, mapping in (
        ("categoryIconsByCode", codes),
        ("categoryIconsByName", {key.lower(): value for key, value in names.items()}),
    ):
        output.append(f"const {name} = <String, IconData>{{")
        for key, icon in sorted(mapping.items()):
            output.append(f"  {json.dumps(key, ensure_ascii=True)}: Icons.{icon},")
        output.extend(["};", ""])
    return "\n".join(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check the committed generated catalog")
    args = parser.parse_args()
    content = generate()
    if args.check:
        # Formatting is applied by dart format after generation.
        import subprocess
        import tempfile
        with tempfile.TemporaryDirectory(dir=ROOT / "tool") as directory:
            target = Path(directory) / "catalog.dart"
            target.write_text(content)
            subprocess.run(["dart", "format", str(target)], check=True, capture_output=True)
            if not OUTPUT.exists() or OUTPUT.read_text() != target.read_text():
                raise SystemExit("Category catalog is stale; regenerate and dart format it.")
        print("Category icon catalog matches the taxonomy and curated assignments.")
    else:
        OUTPUT.write_text(content)
        print(f"Generated {OUTPUT}")
