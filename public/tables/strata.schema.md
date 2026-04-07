# Schema for strata.tsv

Strata are volumes of natural or artificial bodies that have defined resource composition, or are templates for resource composition in the case of generic strata. Most strata have the simplified geometry of a sphere or sphere shell, or a fraction thereof (where spherical fraction is defined but not area boundaries). Strata are described in `strata.descriptive.md`.


## Fields

- name (1st column) — See Name Construction below.
- generic_body_class — Empty unless generic strata.
- body — Non-generic strata only. Body type (e.g., PLANET, MOON, ASTEROID) followed by body name (usually the section name in strata.md; for Small/Undifferentiated Bodies section, extract body name from the item name). Examples: PLANET_EARTH, MOON_MOON, PLANET_MARS, MOON_PHOBOS.
- body_radius — Mean radius of the body (to sea level or other standard reference).
- polity — Usually empty. For Earth "continental" strata, it is the regional subdivision defined in strata.md note 5 (except Antarctica which is empty).
- stratum_group — Item name without body or territory prefix. Abbreviate CONTINENTAL as CONT. In the case of Small/Undifferentiated Bodies and Generic, it is simply BULK.
- depth — Mean radius minus inner boundary radius of the specific stratum. For bulk strata, mean radius of the body. 0 for generic strata.
- thickness — Thickness of the stratum. For bulk strata, this should be the same as depth. 0 for generic strata.
- spherical_fraction — Fraction of spherical area for strata that include regional boundaries (e.g., Earth territories, Moon terrae versus maria, Mars polar cap, etc.). Use 1 when not applicable, including generic strata.
- area — Surface area of the stratum at its outer radius boundary, treating all bodies as spherical. 0 for generic strata.
- volume — Volume of the stratum. 0 for generic strata.
- density — Mean density of the stratum. Mean expectation density for generic strata.
- mass — Total mass of the stratum. 0 for generic strata.
- survey_level — A value from 0 to 10 (decimals allowed) that indicates our relative knowledge about the stratum composition and deposit locations in it. Construct the scale considering all strata listed in strata.md. 0 for generic strata. For calibration:
   - 0. No knowledge.
   - 0.5 Theoretical models with moderate uncertainty.
   - 2.5. Lunar regol ith (excluding polar).
   - 5. Earth near-surface areas that have been extensively explored for resource extraction.
   - 7. Earth surface that is fully surveyed and explored.
   - 10. Earth atmosphere — near perfect knowledge of a mostly homogeneous composition (no uncertainty about deposits).
- survey_note — A very brief qualitative note that justifies the value provided in survey_level. "NA" for generic strata.


## Name Construction

The `name` field is constructed as follows:
- For non-generic strata, join body, territory if applicable (from strata.md note 5, including ANTARCTICA), and strata_group. Examples: PLANET_EARTH_ATMOSPHERE, PLANET_EARTH_ANTARCTICA_CONT_ICE_BODIES, PLANET_EARTH_USA_CONT_SHELF.
- For generic strata, convert the strata name to CONSTANT_CASE. Example: CLASS_M_BULK.


## Notes

1. Internal consistency is required within a stratum given the simplified geometry (see Tests).
2. Adjacent strata won't always "fit" perfectly at boundaries. These will be misaligned where a boundary is an area-weighted mean adjacent to strata of different thicknesses, e.g., the Moon's mantle upper boundary adjacent to Maria and Terrae crust. However, adjacent boundaries should be reasonably close on the scale of body_radius.
3. Atmospheres will have tiny mean densities given the volume construction; this is OK.
4. Don't worry too much about getting survey_level exactly right; these will be cross-calibrated after we have all strata.
5. Resource compositions of strata are defined in strata_resources.tsv.


## Tests

Verify within rounding error:

1. Lengths consistency within a stratum:
  - For bulk strata: body_radius = depth = thickness
  - For innermost strata (usually "Core"): body_radius = depth > thickness
2. Area:
  - Bulk or innermost strata (as sphere): area = spherical_fraction × 4π × thickness^2
  - Calculate: inner_radius = body_radius - depth; outer_radius = inner_radius + thickness. area = spherical_fraction × 4π × outer_radius^2
3. Volume:
  - Bulk or innermost strata (as sphere): volume = spherical_fraction × 4π/3 × thickness^3
  - Thin shell approximation (if thickness <= 1% of inner_radius): volume = area × thickness
  - Sphere shell (if thickness > 1% of inner_radius): volume = spherical_fraction × 4π/3 × (outer_radius^3 - inner_radius^3)
3. mass = volume × density.
