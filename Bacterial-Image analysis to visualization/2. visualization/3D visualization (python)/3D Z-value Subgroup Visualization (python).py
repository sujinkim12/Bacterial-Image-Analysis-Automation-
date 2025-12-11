# ========================================================================
# 3D Z-value Subgroup Visualization (python)
# Author: Sujin Kim
# Created: 2025-08-19
# Last Modified: 2025-12-10
# Description:
#   - Loads multi-sheet HTS Excel data (IC50, MIC, 9xMIC)
#   - Performs Z-value thresholding into group1/group2
#   - Exports subgroup-specific transparent PNGs
# NOTE:
#   • This version uses placeholder file paths for GitHub.
#   • Replace PATH/TO/... with your actual local directory.
# ========================================================================

import os
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import matplotlib.colors as mcolors


###############################################################################
# 1. ANTIBIOTIC GROUP MAPPING
###############################################################################
# Maps each antibiotic abbreviation to either:
#   - "non_beta"      (non β-lactam)
#   - "beta"          (β-lactam)
#   - "all"           (strain does not require per-antibiotic grouping)
# This mapping is only used to select the visualization config.
ANTIBIOTIC_GROUP = {

    # A. baumannii (single antibiotics) — Non β-lactam
    "amk": "non_beta", "gen": "non_beta", "tgc": "non_beta", "tet": "non_beta",
    "lvx": "non_beta", "cip": "non_beta", "rif": "non_beta", "cst": "non_beta",
    "pmb": "non_beta", "van": "non_beta",

    # A. baumannii (single antibiotics) — β-lactam
    "caz": "beta", "azetreonam": "beta", "meropenem": "beta", "fdc": "beta",

    # A. baumannii (combination antibiotics)
    # No antibiotic-specific grouping is required.
    # All antibiotics share the same visualization config ("all").

    # PAO1 — Non β-lactam
    "chir": "non_beta", "pf": "non_beta", "dox": "non_beta",

    # PAO1 — β-lactam
    "caz_p": "beta", "azetreonam_p": "beta", "meropenem_p": "beta",

    # S. aureus
    # No antibiotic-specific grouping is required.
    # All antibiotics share the same visualization config ("all").
}


###############################################################################
# 2. CONFIG (strain × antibiotic group)
###############################################################################
# Each block defines:
#   - z_lim:        threshold between group1 (discrete palette) and group2 (gradient)
#   - index_mode:   strain-specific rule for group1 binning
#   - bin_size:     group1 bin width
#   - axis_xy:      range for X and Y axes
#   - axis_z:       Z-axis range
#   - tick_xy:      tick interval for X,Y
#   - tick_z:       tick interval for Z

CONFIG = {

    "AB_single": {
        "non_beta": {
            "z_lim": 95,
            "index_mode": "ab",
            "bin_size": 10,
            "axis_xy": 180,
            "axis_z": 180,
            "tick_xy": 20,
            "tick_z": 20
        },
        "beta": {
            "z_lim": 95,
            "index_mode": "ab",
            "bin_size": 10,
            "axis_xy": 180,
            "axis_z": 200,
            "tick_xy": 20,
            "tick_z": 20
        }
    },

    "AB_combi": {
        "all": {
            "z_lim": 95,
            "index_mode": "ab",
            "bin_size": 10,
            "axis_xy": 180,
            "axis_z": 180,
            "tick_xy": 20,
            "tick_z": 20
        }
    },

    "PAO1": {
        "non_beta": {
            "z_lim": 160,
            "index_mode": "pa",
            "bin_size": 20,
            "axis_xy": 180,
            "axis_z": 180,
            "tick_xy": 20,
            "tick_z": 20
        },
        "beta": {
            "z_lim": 160,
            "index_mode": "pa",
            "bin_size": 20,
            "axis_xy": 180,
            "axis_z": 600,
            "tick_xy": 20,
            "tick_z": 100
        }
    },

    "SA": {
        "all": {
            "z_lim": 160,
            "index_mode": "sa",
            "bin_size": 10,
            "axis_xy": 180,
            "axis_z": 180,
            "tick_xy": 20,
            "tick_z": 20
        }
    }
}


###############################################################################
# 3. CONFIG SELECTION
###############################################################################
def get_axis_config(strain, antibiotic):
    """Select strain × antibiotic group configuration based on mapping."""

    antibiotic = antibiotic.lower()
    group = ANTIBIOTIC_GROUP.get(antibiotic, "non_beta")

    strain_cfg = CONFIG[strain]

    if group in strain_cfg:
        return strain_cfg[group]
    if "all" in strain_cfg:
        return strain_cfg["all"]

    raise ValueError(f"[CONFIG ERROR] No group found for strain={strain}, antibiotic={antibiotic}")


###############################################################################
# 4. DATA LOADING
###############################################################################
def load_all_sheets(file_path):
    """Load all sheets from the multi-sheet HTS Excel file."""
    xls = pd.ExcelFile(file_path)
    dfs = []

    for sheet in xls.sheet_names:
        df = pd.read_excel(xls, sheet_name=sheet,
                           na_values=["", "NA", "N/A", ">100"])

        for col in ['X value', 'Y value', 'Z value']:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors='coerce')

        # Determine concentration group
        if "_IC50" in sheet:
            sg = "IC50"
        elif sheet.endswith("_MIC"):
            sg = "MIC"
        elif "_9xMIC" in sheet:
            sg = "9xMIC"
        else:
            continue

        df2 = df[['X value', 'Y value', 'Z value']].copy()
        df2['sheet_name'] = sheet
        df2['shape_group'] = sg
        df2.dropna(inplace=True)
        dfs.append(df2)

    return pd.concat(dfs, ignore_index=True)


def avg_data(df):
    """Compute average X, Y, Z values per sheet × shape_group."""
    return df.groupby(['sheet_name', 'shape_group'], as_index=False).agg(
        X=('X value', 'mean'),
        Y=('Y value', 'mean'),
        Z=('Z value', 'mean')
    )


###############################################################################
# 5. COLOR HANDLING
###############################################################################
def get_group1_index(z, mode, bin_size):
    """
    Compute group1 color index.
    Different strains use different indexing rules:
        - Ab     : (z - 12) // bin_size
        - SA     :  z // bin_size
        - PAO1   :  z // bin_size (20-step bin)
    """
    if mode == "ab":
        return int((z - 12) // bin_size)
    elif mode == "sa":
        return int(z // bin_size)
    elif mode == "pa":
        return int(z // bin_size)
    else:
        return 0


def get_color(z, cfg, actual_max):
    """Return color for each Z value based on group1 or group2 rule."""

    z_lim = cfg["z_lim"]
    mode = cfg["index_mode"]
    bin_size = cfg["bin_size"]

    group1_palette = [
        "grey", "grey", "#9D3CFF", "#00A0FF",
        "#009300", "#E6DC32", "#F08228", "red"
    ]

    cmap = mcolors.LinearSegmentedColormap.from_list(
        "cmap2", ["#FFB3AB", "#D5453F", "#800000", "#311010"]
    )

    # group1
    if z <= z_lim:
        idx = get_group1_index(z, mode, bin_size)
        idx = max(0, min(idx, len(group1_palette) - 1))
        return group1_palette[idx]

    # group2
    norm = mcolors.Normalize(vmin=z_lim, vmax=actual_max)
    rgba = cmap(norm(z))
    return mcolors.to_hex(rgba)


###############################################################################
# 6. MAIN PLOTTING FUNCTION
###############################################################################
def plot_3d_hts(file_path, strain, antibiotic):
    """Generate 3D HTS visualization based on strain × antibiotic settings."""

    cfg = get_axis_config(strain, antibiotic)

    x_range = cfg["axis_xy"]
    z_range = cfg["axis_z"]
    tick_xy = cfg["tick_xy"]
    tick_z = cfg["tick_z"]

    df_all = load_all_sheets(file_path)
    df_avg = avg_data(df_all)

    fig = go.Figure()
    marker_map = {'IC50': "circle", 'MIC': "x", '9xMIC': "square"}

    # RAW points
    max_z = df_all["Z value"].max()
    for sg in df_all['shape_group'].unique():
        sub = df_all[df_all['shape_group'] == sg]
        colors = [get_color(v, cfg, max_z) for v in sub['Z value']]
        fig.add_trace(go.Scatter3d(
            x=sub['X value'], y=sub['Y value'], z=sub['Z value'],
            mode='markers',
            marker=dict(size=4, color=colors, symbol=marker_map[sg]),
            opacity=0.2
        ))

    # AVERAGE points
    max_avg = df_avg["Z"].max()
    for sg in df_avg['shape_group'].unique():
        sub = df_avg[df_avg['shape_group'] == sg]
        colors = [get_color(v, cfg, max_avg) for v in sub['Z']]
        fig.add_trace(go.Scatter3d(
            x=sub['X'], y=sub['Y'], z=sub['Z'],
            mode='markers',
            marker=dict(size=10, color=colors, line=dict(color='black', width=2),
                        symbol=marker_map[sg]),
            opacity=0.8
        ))

    # Layout
    fig.update_layout(
        scene=dict(
            xaxis=dict(range=[0, x_range], dtick=tick_xy, title="X"),
            yaxis=dict(range=[0, x_range], dtick=tick_xy, title="Y"),
            zaxis=dict(range=[0, z_range], dtick=tick_z, title="Z"),
            aspectmode="cube"
        ),
        width=1200,
        height=1000,
        title=os.path.basename(file_path)
    )

    # Save
    out_html = os.path.splitext(file_path)[0] + ".html"
    fig.write_html(out_html)
    print(f"Saved: {out_html}")
