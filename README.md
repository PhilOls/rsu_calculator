# RSU French Tax Calculator

This repository contains a GUI calculator for RSU/free-share French tax declaration support.

It reads Fidelity NetBenefits lot exports, optional other-broker lots/statements, award metadata, Banque de France/Webstat exchange rates, and optional French declaration PDFs.

- `Advise`: rank open lots for sale or transfer/donation planning.
- `Declare`: generate declaration-ready outputs for a past income year.
- `Verify`: compare generated values with real 2042, 2074, and avis/ASDIR PDFs.

## Contents

- [Windows GUI](#windows-gui)
- [macOS and Linux GUI](#macos-and-linux-gui)
- [Input Files](#input-files)
  - [Other-Broker Lots](#other-broker-lots)
    - [Manual Broker Statements and Transfers](#manual-broker-statements-and-transfers)
  - [Award Matching](#award-matching)
- [Common GUI Behavior](#common-gui-behavior)
- [Advise](#advise)
  - [Advise / Common Controls](#advise-common-controls)
  - [Advise / Sale](#advise-sale)
  - [Advise / Transfer/Donation](#advise-transfer-donation)
  - [Advise / Summaries and Cached State](#advise-summaries-and-cached-state)
- [Declare](#declare)
- [View](#view)
- [Verify](#verify)
- [Report Issue](#report-issue)
- [Files in this repository](#files-in-this-repository)

## Windows GUI

Most users should start here:

[Download Windows installer](https://raw.githubusercontent.com/PhilOls/rsu_calculator/main/install_windows.cmd)

After download, open `install_windows.cmd`. Windows may ask for confirmation because it is a command script. The installer clones or updates the calculator into:

```text
%LOCALAPPDATA%\RsuTaxCalculator
```

The installer creates shortcuts named `RSU Tax Calculator` on the Desktop and in the Windows Start Menu. When `pythonw.exe` is available, those shortcuts target `pythonw.exe` directly so normal GUI launch does not keep a console window. `Run RSU Tax Calculator.cmd` remains available as a diagnostic fallback.

If the calculator window does not open automatically after install, start it from the Desktop shortcut or search for `RSU Tax Calculator` in the Windows Start Menu.

Windows requires Python 3.10+ with Tkinter, which is included in the standard Python installer from python.org. The installer installs Python dependencies from the local `wheelhouse/` when possible; the program also checks them at startup.

## macOS and Linux GUI

macOS and Linux machines require Python 3.10+ with Tkinter. On macOS, the Python installer from python.org includes Tkinter. After installing Python, launch the GUI with:

```bash
./run_rsu_tax_calculator.sh
```

The wrapper opens the GUI when run without arguments. To use the command-line calculator, pass its CLI options explicitly. It uses the local `python3` by default; set `PYTHON=/path/to/python3` before the command to use a specific Python installation.

On macOS, file-open dialogs use simple extension filters such as `*.pdf` and `*.csv` for stability with the native Tk file chooser.

On supported Linux cluster machines, the same wrapper loads the provided Python and Tk environment before starting the GUI. Missing Python dependencies are installed by the program at startup, using the local `wheelhouse/` first.

## Input Files

In the GUI, select input files with the file pickers; they do not need to be stored beside the program.

- `View closed lots.csv`: Fidelity NetBenefits `Previously held shares` export
- `Fidelity NetBenefits - Awards Details.pdf`: optional Fidelity NetBenefits awards-details PDF, used by `Advise` to add future current-year vest rows
- Fidelity transaction history CSV: optional Fidelity NetBenefits transaction-history export, used by `Advise` to reconcile closed-sale proceeds, cash withdrawals, and observed transfer-out rows
- Fidelity transfer form PDFs: optional filled Fidelity transfer forms, used by `Advise` to mark matching lots as `In Transfer`; use `Add...` repeatedly or select several PDFs at once. Each form is shown in its own input row and can be removed. Duplicate forms are still parsed, but identical parsed transfer lots are reconciled once.
- `View open lots.csv`: optional Fidelity NetBenefits `Current shares` export, used for consistency checks and `Advise`
- `Other broker closed lots.csv`: optional user-maintained sold/transferred lots outside Fidelity
- `Other broker open lots.csv`: optional user-maintained current lots outside Fidelity
- Broker statement CSVs: optional activity statements from other brokers, currently recognized for Interactive Brokers transfer-in rows and open positions in `Advise`; use `Add...` repeatedly or select several CSVs at once
- Manual broker statement rows: optional GUI-entered receiving-broker evidence when no supported broker statement export exists. Societe Generale broker tabs expose `Manual SG statement rows`; those rows are stored in local GUI preferences.
- Cloud backup folder: optional local folder synced by Google Drive or another cloud client. `Backup now` copies currently selected evidence files there, and `Fill Transfer Form` runs the same backup before writing the form.
- `Webstat_Export_fr_5385698.csv`: Banque de France/Webstat exchange-rate CSV export

When running in command-line mode, the calculator asks for the CSV path if the closed-lots file cannot be found. You can also place `View closed lots.csv` beside the program or specify its location with `--closed-lots /path/to/file.csv`. In the GUI, the file picker opens when the required closed-lots export is missing.

The Banque de France/Webstat CSV can be downloaded from:

```text
https://webstat.banque-france.fr/export/csv-columns/fr/selection/5385698
```

The GUI can download the Banque de France/Webstat exchange-rate CSV directly. If Python cannot validate the server certificate, the app retries with the system `curl` command while keeping TLS verification enabled. If the download is still unavailable, the GUI displays a copyable download URL and enables the exchange-rate CSV picker.

No user config file is required. Do not commit personal Fidelity exports unless the repository is intended to contain private financial data.

## Other-Broker Lots

Other-broker CSVs are optional and can be created/edited from the GUI. Use them for non-Fidelity assets such as other-company RSUs, ESPP, or normal traded shares. Money columns are in USD; the calculator applies Banque de France/Webstat exchange rates.

`Other broker closed lots.csv` headers:

```text
issuer,broker,plan,lot_type,tax_type,sale_type,acquired,sold,quantity,proceeds_usd,cost_basis_usd,term,notes
```

`Other broker open lots.csv` headers:

```text
issuer,broker,plan,lot_type,tax_type,acquired,quantity,cost_basis_usd,value_usd,sale_availability_date,transfer_availability_date,holding_period,notes
```

Accepted date formats include `YYYY-MM-DD` and `DD/MM/YYYY`. Set `tax_type` to `Qualifié` only for lots that must feed the qualified free-share acquisition-gain calculation; otherwise use `NonQualifié` for capital-gain-only treatment.

### Manual Broker Statements and Transfers

Use manual broker statement rows when the receiving broker does not provide a supported statement export, but the account still gives enough evidence to confirm a position or transfer. In the main GUI, add or select a `Societe Generale` broker tab, then use `Manual SG statement rows`.

For a transfer in from Fidelity, attaching the transfer form PDF is optional. When available, the popup parses it and pre-fills the symbol and quantity. For a paper-only confirmation, enter the symbol, total quantity, receipt date, sending institution, and recipient owner manually. The app confirms receipt only when it can match the symbol and quantity to Fidelity-observed transfer-out lots; unmatched or ambiguous rows remain unconfirmed. The Fidelity lot exports remain the source of original acquisition date, cost/share, tax type, and plan details.

The same Fidelity transfer form may also remain selected in the normal transfer-form list for the sending side. However, a given transfer form can only be attached to one manual statement row, to avoid double-confirming the same received shares.

Manual rows can also represent a simple manually confirmed position, a transfer out, or a donation to another owner. To allocate an outgoing transfer to specific lots, open `Advise`, select available source rows from one institution in `Transfer/Donation`, and right-click the selection to choose `Record Transfer Out / Donation...`. Choose the recipient owner, receiving institution, date, and quantity; the entered quantity can be less than the selected shares, and the calculator splits lots as needed while preserving the original owner's acquisition date, plan, share source, tax type, and basis. Only the donated quantity is marked `[D]`; any remainder keeps its prior received/available state (`[R]` or blank) and is not reclassified as an in-progress or observed transfer just because the lot was split. Record one recipient at a time; after saving, the remaining shares can be selected for another recipient. The optional receiving share price (`USD` or `EUR`) becomes the recipient's new capital-gain basis; an EUR price is converted with the Banque de France/Webstat rate on or before the transfer date. A donation is projected into the recipient owner's Advise view. These records are stored with the Societe Generale manual statement rows in `gui_preferences.json`. To undo, right-click any row in `Transfer/Donation` and choose `Undo Last Recorded Donation...`; confirm the details to remove that saved donation and its recipient projection. The undo is saved in GUI preferences and remains in effect after restarting the app. It does not alter existing backup copies.

For transfer in from Fidelity, the Fidelity transfer form is optional; the calculator can also preserve an observed transfer-out lot's original tax-lot details when receipt is confirmed manually in Advise.

Manual statement rows are stored in `gui_preferences.json`. `Backup now` includes the GUI preferences file, so these rows are part of the normal backup and restore flow.

## Award Matching

`rsu_award_catalog.json` intentionally excludes user share quantities and sold-lot assignments. The calculator infers sold-lot award plans from:

- grant-date mappings in `rsu_award_catalog.json`
- vesting dates and plan classifications in `rsu_award_catalog.json`
- open-lot evidence from `View open lots.csv`, when provided
- closed-lot acquisition/sale dates from `View closed lots.csv`

When no matching open lot remains for an acquisition date and more than one award-catalog award vested that day, the Detail sheet marks the assignment as `REVIEW`.

## Common GUI Behavior

The Windows, macOS, and Linux GUIs let you select the Fidelity CSV files, optional other-broker CSV files, exchange-rate CSV, award catalog, optional real 2042 declaration PDF, optional avis d'impôt / ASDIR PDF, optional real 2074 declaration PDF, income year, and output folder.

Date fields in GUI forms use a calendar picker and store dates in unambiguous `YYYY-MM-DD` form, regardless of the computer's regional date format.

At startup, and occasionally after major actions, the GUI checks whether the local Git checkout is behind `origin/main`. If a newer version is available, the lower `Update now` button next to `Report Issue` and `Exit` is highlighted when the calculator is idle; clicking it when already current is safe. After an effective update, the button becomes `Restart now` so the calculator can relaunch with the updated version. If the checkout changes on disk while the GUI is running, the updater offers `Restart now` even when GitHub is already current, so the open window can load the new files. If tracked local changes are present, auto-update is skipped to avoid overwriting local work, but the button still offers `Restart now` so a running GUI can relaunch with the current local files.

If no open-lots export exists because all shares were sold, leave the `Open lots CSV` field empty. If the selected path is missing, the calculator skips Fidelity open-lot consistency checks.

The optional `Other broker closed lots CSV` and `Other broker open lots CSV` rows have an `Edit...` button. If no file is selected yet, the editor asks where to create the CSV, writes the required header, and lets you enter rows directly. The closed-lots file is included in `Declare`; the open-lots file is remembered and can be included in `Advise`.

The `Download` button beside the exchange-rate CSV field downloads the Banque de France/Webstat CSV into `.cache/` and selects it if the machine can reach the Banque de France site. If it cannot, download the CSV elsewhere and select it manually in the exchange-rate CSV field.

Parsed PDF text is cached locally in `.cache/` with file path, size, modification time, and SHA-256 metadata. Reusing unchanged transfer forms, Fidelity award details, 2042, avis/ASDIR, or 2074 PDFs should avoid repeated PDF extraction work.

The `CF` button beside the 2042 declaration PDF lets you override selected non-share-plan 2042 values before they are carried forward in `Projected` mode. By default, the parsed PDF values are used unchanged; edited carry-forward values are remembered locally per owner and per PDF.

The GUI defaults the income year to the previous calendar year. For example, when run in 2026 it computes the 2026 declaration for 2025 income unless another year is selected.

Closed-lot rows sold after the selected income year are ignored. This allows a current `View closed lots.csv` export to contain current-year sales before exchange rates for that year are available.
Closed-lot rows sold before the selected income year are also ignored for the selected declaration. The output reports both prior-year and later-year ignored rows, with a breakdown by broker/share source such as `Fidelity / RSU` or `Other broker / Other issuer / Shares`.

The GUI loads shared receiving-institution defaults from `fidelity_receiving_institutions.json` for the Fidelity transfer form. This shared JSON must contain only institution-level data. User-specific fields such as receiving account number, account holder name, and intermediary account number are prompted in the GUI and stored only in the user's local GUI cache.

The default output prefix is:

```text
rsu_tax_declaration_<declaration_year>_income_<income_year>
```

For income year 2024, the GUI writes files named:

```text
rsu_tax_declaration_2025_income_2024.detail.csv
rsu_tax_declaration_2025_income_2024.summary.json
rsu_tax_declaration_2025_income_2024.xlsx
```

## Advise

`Advise` ranks the open lots from the selected Fidelity Current shares export and optional other-broker open lots CSV for two use cases:

- `Sale`: minimizing estimated tax when selling
- `Transfer/Donation`: minimizing estimated tax when transferring or donating shares

This feature produces estimates only; review the output before acting.

<a id="advise-common-controls"></a>

### Advise / Common Controls

If a Fidelity awards-details PDF is selected, `Advise` also adds future current-year unvested RSU rows from that PDF. These rows are marked as `Future vest`, highlighted in the table, and can be selected individually or with the `Select Future` / `Clear Future` buttons. Future-vest rows use the current price for their share symbol as simulated sale/transfer value. For acquisition basis, the calculator first uses a weighted cost-basis/share estimate from existing open lots for the same grant, then the same plan, then the same award family with the same tax type; only if no matching open-lot basis is available does it fall back to the current symbol price as a placeholder.

Fidelity's `Next distribution` value in award details is an aggregate of the already-listed unvested rows for that distribution date; it is not an additional award. `Advise` therefore builds future rows from the detailed unvested award rows only, not from the top-level next-distribution total.

The `Advise` window shows one USD price field per share symbol present in the Advise tables, for example `RSU price USD` and `CDNS price USD`. Each refresh icon attempts to fetch a live quote for that symbol; when the regular market is closed, the latest available chart close is used. If Python cannot validate the quote server's TLS certificate, the app retries with the system `curl` command while keeping certificate verification enabled. If live quote access is blocked or unavailable, the tooltip shows the fetch error and you can type a manual USD/share price in that symbol's field. The adjacent chart icon opens that symbol's Yahoo Finance quote chart in the configured browser. When live quote metadata says the regular market is closed, the refresh icon changes to a closed-market marker and the tooltip reports the market status. On Linux, corporate proxy access can block quote fetching, so manual prices may still be needed.

Select the `Tax rate` mode/value used for acquisition-gain tax estimates in both `Advise` and `Declare`. If a same-year avis d'impôt is selected and readable, the GUI switches to `Avis` and uses the marginal rate parsed from that notice. Otherwise, choose `Auto` to estimate the incremental progressive-barème tax from the selected same-year 2042 declaration PDF, or `Projected` to carry a prior-year 2042 baseline forward after removing prior-year share-plan boxes. `Projected` is allowed for the active declaration income year and for current/future-year `Advise` planning; older income years require `Auto` with same-year documents or a fixed tax rate.

If the 2042 `CF` overrides are set, `Projected` uses those adjusted carried-forward baseline values for progressive tax-rate and CEHR/CDHR estimates.

Tick rows in the `Advise` tables to see selected-lot totals, estimated tax, and estimated after-tax proceeds/value, converted with the latest available Banque de France/Webstat rate. A `[-]` row is greyed out because the same lot is already selected in the other `Advise` tab.

Common row markers in `Advise`:

- `[X]`: selected in the current tab; hover over the marker for details
- `[-]`: selected or blocked by the other tab; hover over the marker for details
- `[C]`: already closed/sold for the selected income year; hover over the marker for details
- `[S]`: temporarily marked sold by the user while waiting for refreshed Fidelity exports; hover over the marker for details
- `[P]`: placed sale order simulated at a limit price; hover over the marker for details
- `[E]`: expired Day limit sale order; the row is available again and uses the current quote/manual price; hover over the marker for details
- `[I]`: transfer currently in progress; hover over the marker for details
- `[D]`: donation recorded in a manual broker statement row; hover over the marker for details
- `[O]`: transfer-out observed in Fidelity transaction history, without confirming transfer-in at the receiving institution; hover over the marker for details
- `[R]`: transfer-in confirmed from a receiving-broker statement, manual statement row, or Advise confirmation; the row is available again for Sale or Transfer/Donation selection; hover over the marker for details

<a id="advise-sale"></a>

### Advise / Sale

When a closed-lots export contains sales for the selected income year, the `Sale` tab also shows them as read-only `Closed sale` rows. They are included automatically in the Sale tax summary, and the summary adds `Closed sale cash` before the estimated after-tax proceeds line. Sell-to-cover / tax-cover proceeds stay in the tax calculation but are excluded from `Closed sale cash` and estimated after-tax proceeds because that cash was used for withholding.

If a Fidelity transaction-history CSV is selected, the `Sale` tab can show extra cash context such as withdrawals, closed cash after withdrawals, and transfer-out observations. Transaction history is only a reconciliation aid; tax rows still come from the closed-lots export and other-broker closed-lots CSV.

If broker statement CSVs or manual statement rows are selected, `Advise` auto-detects each recognized broker and can match receiving-broker transfer-in rows against lots that were in transfer or observed as transferred out from Fidelity. Matching rows are shown as `[R]` and are available again for Sale or Transfer/Donation selection at the receiving broker. Recognized non-RSU open stock positions from broker statements are also shown in Advise with their own symbol and quote field. Selecting the same statement more than once does not double-count it.

Use `Mark Sold` / `Clear Sold` in the `Sale` tab to temporarily mark one or more open or future-vest rows as sold at a user-entered sale price, including available split rows left by an expired Day order. These rows are shown as `[S]`, included in Sale estimates, and remembered locally by income year. This is intended for the short gap before the broker publishes refreshed lot data or statements. After refreshed broker/lot data confirms the sale, the stale `[S]` cache is dropped and the `[C]` row uses the broker's actual closed-lot proceeds.

Use `Place Order` / `Clear Order` in the `Sale` tab to simulate one or more whole-lot limit sale orders with Day or Good till cancel validity and an optional all-or-none flag. Active order rows are shown as `[P]`, included in Sale estimates at the limit price, and blocked from Transfer/Donation until cleared or confirmed. Use `Mark Sold` on a `[P]` row if the broker shows the order executed before refreshed lot data is available; the sale-price prompt defaults to the order limit price. A Day order expires automatically after its order date; the row becomes `[E]`, is available again, and returns to the current quote/manual price for estimates. If a real live quote is available and reaches or exceeds an active stored limit price, the row highlight changes and the GUI shows an alert. The alert can either mark the reached rows as `[S]` at their limit price or ignore the alert. This alert is only triggered by a successful live quote refresh, not by manual/default prices.

The `Sale` tab applies the PFU rate for the selected income year to positive net capital gain: 30% through income year 2025, 31.4% from income year 2026.

<a id="advise-transfer-donation"></a>

### Advise / Transfer/Donation

In the `Transfer/Donation` tab, right-click a row to access `Mark In Transfer` / `Clear In Transfer` and transfer receipt actions. If you have highlighted multiple rows, right-click one of them to act on the eligible highlighted rows together; right-clicking an unselected row makes it the only highlighted row. Marking a lot in transfer means its transfer is currently in progress, not that it has already arrived. Marked rows are remembered locally by income year, shown with `[I]`, pinned above the normal ranked rows, and excluded from sale/transfer selection. To record receipt without a transfer-form PDF or receiving-broker statement, highlight one or more eligible `[O]` rows and choose `Confirm Transfer In` from the right-click menu. Enter the receiving institution and receipt date; the calculator retrieves Yahoo Finance's historical daily closing price for each symbol and records shares multiplied by that price. On weekends or market holidays, it uses the most recent available close on or before the receipt date. This is a market estimate, not the broker's confirmed transfer value or an intraday execution price. If a historical quote cannot be fetched, you can still record receipt and the tooltip will identify its value as the current Advise estimate. Confirmed rows become `[R]` and are available again for Sale or Transfer/Donation. A recorded donation splits only the allocated shares; existing receipt confirmations for other lots remain intact. Use `Clear Transfer In Confirmation` from the menu to undo a manually recorded confirmation; clear and re-confirm earlier manual confirmations to fetch their historical values. These owner- and income-year-specific confirmations and quote values are saved in GUI preferences and included in `Backup now`.

If one or more filled Fidelity transfer form PDFs are selected in the main window, `Advise` also parses their tax-lot rows and automatically marks matching lots as `In Transfer`. Matching uses acquisition date, cost basis/share, and quantity. If the form transfers part of a larger open lot, the lot is split into an `In Transfer` row for the transferred quantity and a separate remaining row that stays selectable. The `Reason` column names the receiving institution parsed from the form.

The `Transfer/Donation` tab also has `Fill Transfer Form`, which prompts for cached participant details and a separately cached receiving-institution profile before writing a copy of the bundled Fidelity transfer-of-assets form. The prompt lets the user review or change participant details, receiving-institution details, trade date, settlement date, and an optional signature image. If every displayed transfer/donation lot is ticked, the form's `"All Available"` box is ticked; otherwise, up to three ticked lots fill the tax-lot table directly, and more than three use appended separate sheet pages containing all selected lots. The form output filename includes the receiving-institution profile name and the current date.

Why backup matters: after shares leave Fidelity, Fidelity may no longer show the original lot, and the receiving broker may show only transfer-date market basis. The pre-transfer Fidelity open-lots export is the evidence that preserves original acquisition date, cost/share, grant date, share source, and qualified/non-qualified classification for later French tax tracking.

Before writing a transfer form, the GUI warns about this and offers to back up relevant files. The GUI tries to detect whether Google Drive exposes a local synced folder and shows the result beside the Cloud backup folder. The calculator does not authenticate to Google Drive; it only copies to a local synced folder when Google Drive for desktop, or another cloud sync client, exposes one.

`Backup now` and the transfer-form flow back up relevant selected files: GUI preferences, Fidelity exports, broker statements, transfer forms, declaration PDFs, exchange rates, and the award catalog. The GUI preferences file contains local state such as owners, broker tabs, and manual statement rows. `Backup now` also includes generated calculator outputs only when they come from the last successful `Declare` run or Verify-computed declaration model in the current app session. Backups are tracked by SHA-256 content hash in `rsu_backup_manifest.json`; unchanged content is skipped, and a same filename with different content gets a distinct backup filename.

After a transfer form is generated, the GUI can prepare an email draft to Fidelity Stock Plan Services with the generated form attached when the local email program supports it. The user must still review and send the email manually from the email program. The receiving institution can optionally be added in copy if an email address is provided. The GUI can also mark the selected lots as `In Transfer` after the form is generated.

The `Transfer/Donation` tab assumes no capital-gain tax and still estimates any qualified acquisition-gain tax.

<a id="advise-summaries-and-cached-state"></a>

### Advise / Summaries and Cached State

Selected `Advise` lots are cached locally by income year and restored when the calculator is restarted or the `Advise` window is reopened.

The acquisition-tax summary row shows the tax-rate source, for example `Acq. tax @ Avis 41%` or `Acq. tax @ Projected 41%+45%`. Use the `?` beside that row to see the rate or bracket calculation details.

When `Auto` or `Projected` is used in `Advise`, already-closed lots for the selected income year are included before the hypothetical selected open lots for the progressive acquisition-tax estimate. This matters when already-sold qualified lots push the next selected lot into a higher bracket.

Use `Select Target` to auto-select whole lots until the chosen EUR target is reached or crossed. In the `Sale` tab, the target can use selected estimated after-tax proceeds alone or closed cash plus selected estimated after-tax proceeds. In the `Transfer/Donation` tab, the target uses estimated after-tax value. Lots are not split by this helper.

In the `Transfer/Donation` table, Shift-click or Control-click rows to select or deselect multiple eligible lots for the estimate; ordinary row highlighting remains available for copying. You can also toggle individual lots using the leftmost selection cell.

Use `Export CSV` to save the selected lots from the current `Advise` tab. Use `Copy Selected Rows` or `Copy Summary` to copy the current table selection or summary values.

## Declare

Use `Declare` for a past income year where the declaration can be prepared from actual sold lots. Current and future income years are `Advise`-only; the current-year/future-year `Estimate` action is disabled, and the year selector exposes planning years through current year + 2, such as 2028 when running in 2026.

If a past income year already has all three official PDFs selected (`2042`, `2074`, and avis/ASDIR), the `Declare` action is disabled. Use `Verify` instead; it computes the declaration model internally and compares it with the selected PDFs.

`Declare` reads closed lots, optional other-broker closed lots, award classifications, and exchange rates, then generates the CSV, JSON, and XLSX outputs.

Generated files:

- detail CSV
- summary JSON
- XLSX workbook with 2042, 2074, 2074.11, and Detail sheets

The `2042` sheet summarizes the declaration boxes and gives the French meaning of each box. The `2074` sheet is laid out like the declaration: one row for each workbook 2074 line, including line 511, and one column per sale operation. The `Detail` sheet contains the full calculation trace.

After completion, the text output and the generated `2042` sheet include a simple estimated-tax calculation. The capital-gain part uses `max(0, 3VG - 3VH) x PFU`. With `Avis`, the acquisition-gain part uses the marginal rate parsed from the same-year avis d'impôt. With a fixed tax rate, it uses `(1TZ + 1TT) x selected tax rate`; with `Auto` or `Projected`, it estimates the acquisition-gain tax as the difference between progressive income tax before and after adding `1TZ + 1TT` to the parsed 2042 baseline. If the selected income year's official brackets are not encoded yet, the progressive estimate reuses the latest known brackets and states that in the output. `1WZ` is displayed as the 50% abatement box and is not added again to the taxable base.

`Declare` can run an RFR/CEHR/CDHR check. If a text-readable real 2042 declaration PDF is selected, it estimates RFR from available 2042 boxes and marks it clearly as an estimate. It uses the selected 2042 PDF as the baseline for non-RSU fields such as wages, overtime, RCM/life-insurance boxes, and PER deduction context, then replaces share-plan boxes with the current calculator result for the selected income year.

If an optional avis d'impôt / ASDIR PDF is provided, `Declare` also parses its official RFR and shows a calibration against the 2042-box estimate for the baseline year. When the avis income year matches the calculator income year, the official RFR from that avis is used for CEHR/CDHR threshold screening instead of the 2042-based estimate. A same-year avis can be used for CEHR/CDHR screening even when no 2042 PDF is selected.

The main output shows only the RFR/CEHR/CDHR conclusion, including a short RFR basis and any CEHR amount; computed CEHR/CDHR amounts are also included in the GUI estimated-tax total. CEHR smoothing is attempted when RFR evidence is available for the two previous income years, preferably from avis/ASDIR PDFs and otherwise from 2042-box RFR estimates. If Y-1 or Y-2 RFR evidence is missing, the output warns and keeps the direct CEHR band estimate. If CDHR is flagged but not computable, the GUI says it is excluded instead of adding a guessed value. Use `Details` to view the input documents, full RFR source, and full calculation. The 2042 declaration PDF does not contain the official RFR; use the later ASDIR/avis d'impôt for the official number.

When `Projected` uses a prior-year 2042 baseline, any saved 2042 `CF` overrides are reflected in the carried-forward RFR, CEHR, and CDHR details.

## View

After a successful `Declare` run or Verify-computed declaration model, `View` lets you browse the generated `2074` values one title at a time: `Titre 1`, `Titre 2`, and so on. In that viewer, editable rows have a `Copy` cell that copies the row value to the clipboard.

## Verify

If the optional real 2042, avis d'impôt / ASDIR, or 2074 declaration PDF fields point to existing PDFs, the GUI enables `Verify` after a successful `Declare` run for that income year. If all three official PDFs are selected for a past income year, `Verify` is enabled without a prior `Declare` run and computes the declaration model internally before comparing the PDFs.

`Verify` uses `pypdf` to:

- compare the real 2042 against the generated boxes `1TZ`, `1WZ`, `1TT`, `3VG`, and `3VH`
- compare the avis `Plus-values et gains divers 47` base and social contributions against the generated share-plan values
- compare the real 2074 against the generated `2074` and `2074.11` values

Per-title 2074 mismatches identify `Titre 1`, `Titre 2`, and so on.

## Report Issue

`Report Issue` prompts for a short issue description, adds the current program Git revision automatically, and opens a prefilled GitHub issue page in the browser. Review the issue before submitting it. The calculator does not attach Fidelity exports, payroll files, or declaration PDFs.

## Files in this repository

- `rsu_tax_calculator.py`: calculator program
- `run_rsu_tax_calculator.sh`: macOS/Linux GUI wrapper
- `run_rsu_tax_calculator_windows.bat`: Windows GUI launcher
- `install_windows.cmd`: double-clickable Windows installer wrapper
- `requirements.txt`: Python dependencies, including `pypdf` for declaration PDF verification
- `wheelhouse/`: local Python wheels used when PyPI is not reachable
- `rsu_award_catalog.json`: generic award catalog, Fidelity mapping hints, vesting dates, and French tax classifications
- `fidelity_receiving_institutions.json`: shared receiving-institution defaults for the Fidelity transfer form, without user account numbers
- `Forms/Fidelity_Transfer_of_Assets_form.pdf`: blank Fidelity Stock Plan Services transfer-of-assets form used by the `Advise` helper

At startup, the program checks the required Python packages and automatically installs missing dependencies from `requirements.txt`. It tries the local `wheelhouse/` first, then falls back to the online Python package index. The Windows installer uses the same local-first dependency install during install/update.

## Notes

This is not formal tax advice. The output reproduces the workbook-style calculation used during development and should be reviewed against the user's Fidelity exports, award documents, payroll evidence, and French declaration requirements.

## Suggestions for a good README

Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Badges
On some READMEs, you may see small images that convey metadata, such as whether or not all the tests are passing for the project. You can use Shields to add some to your README. Many services also have instructions for adding a badge.

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Installation
Within a particular ecosystem, there may be a common way of installing things, such as using Yarn, NuGet, or Homebrew. However, consider the possibility that whoever is reading your README is a novice and would like more guidance. Listing specific steps helps remove ambiguity and gets people to using your project as quickly as possible. If it only runs in a specific context like a particular programming language version or operating system or has dependencies that have to be installed manually, also add a Requirements subsection.

## Usage
Use examples liberally, and show the expected output if you can. It's helpful to have inline the smallest example of usage that you can demonstrate, while providing links to more sophisticated examples if they are too long to reasonably include in the README.

## Support
Tell people where they can go to for help. It can be any combination of an issue tracker, a chat room, an email address, etc.

## Roadmap
If you have ideas for releases in the future, it is a good idea to list them in the README.

## Contributing
State if you are open to contributions and what your requirements are for accepting them.

For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.

You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## Authors and acknowledgment
Show your appreciation to those who have contributed to the project.

## License
For open source projects, say how it is licensed.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
