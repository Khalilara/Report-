// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

#let country-report(
  title: "title",
  country_code: "GBR",
  color: "#036531",
  body,
) = {
  
 set text(
    font: "Open Sans",
    size: 12pt,
  )

 set page(
    "us-letter",
    margin: (left: 0.5in, right: 0.5in, top: 0.55in, bottom: 0.0in),
    background: place(top, rect(fill: rgb(color), width: 100%, height: 0.5in)),
    header: align(
      horizon,
      grid(
        columns: (80%, 20%),
        align(left, text(size: 20pt, fill: white, weight: "bold", title)),
        align(right, text(size: 12pt, fill: white, weight: "bold", country_code)),
      ),
    ),
    // footer: align(
    //   grid(
    //     columns: (40%, 60%),
    //     align(horizon, text(fill: rgb("15397F"), size: 12pt, counter(page).display("1"))),
    //     align(right, image("path/to/logo.svg", height: 300%)),
    //   )
    // )
  )
  body
}

#show: doc => article(
  title: [Sales Performance Report],
  authors: (
    ( name: [Greate Khalil],
      affiliation: [],
      email: [] ),
    ),
  date: [2025-04-18],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

#box(image("report_files/figure-typst/revenue_by_customer-output-1.png"))

#figure([
#box(image("report_files/figure-typst/cell-5-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Figure 1: Revenue by Customer Type
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#table(
  columns: 3,
  align: (auto,auto,auto,),
  table.header([~], [Channel], [Revenue],),
  table.hline(),
  [0], [unmanaged], [\$51,302],
  [1], [Econocom], [\$31,859],
  [2], [Orange], [\$14,735],
  [3], [HELIAQ], [\$13,456],
  [4], [Inmac], [\$5,033],
  [5], [SFR], [\$1,649],
)
#v(-20pt)
#block[
#block[

#horizontalrule

#block[
```
C:\Users\hp\AppData\Local\Temp\ipykernel_32844\4124852666.py:3: UserWarning: set_ticklabels() should only be used with a fixed number of ticks, i.e. after set_ticks() or using a FixedLocator.
  ax.set_xticklabels(rev_df['Channel'], rotation=45, ha='right')
```

]
#figure([
#box(image("report_files/figure-typst/cell-7-output-2.png"))
], caption: figure.caption(
position: bottom, 
[
Figure 2: SMB Revenue by Channel
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#v(-20pt)
#block[
#block[

#horizontalrule

#figure([
#box(image("report_files/figure-typst/cell-8-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Figure 3: SMB Channel Revenue Share
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#v(-20pt)
#block[
#block[

#horizontalrule

#v(-20pt)
#block[
#block[

#horizontalrule

#table(
  columns: 3,
  align: (auto,auto,auto,),
  table.header([~], [Prod Sub], [Count],),
  table.hline(),
  [0], [Knox Suite - Essentials], [35],
  [1], [Knox Suite - Enterprise], [10],
  [2], [Knox Configure], [5],
  [3], [Knox Guard], [1],
)
#v(-20pt)
#block[
#block[

#horizontalrule

#figure([
#box(image("report_files/figure-typst/cell-11-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Figure 4: Knox SW Product Distribution for SMB
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#v(-20pt)
#block[
#block[

#horizontalrule

#table(
  columns: 3,
  align: (auto,auto,auto,),
  table.header(table.cell(align: right)[], table.cell(align: right)[Source], table.cell(align: right)[Value],),
  table.hline(),
  table.cell(align: horizon)[0], [App (Existing)], [\$118,032.98],
  table.cell(align: horizon)[1], [Pipe (Q2)], [€510,587.00],
)
#figure([
#box(image("report_files/figure-typst/cell-13-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Figure 5: Landing Projection
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#v(-20pt)
#block[
#block[

#horizontalrule

#table(
  columns: 6,
  align: (auto,auto,auto,auto,auto,auto,),
  table.header(table.cell(align: right)[], table.cell(align: right)[END CUSTOMER], table.cell(align: right)[SOLUTION], table.cell(align: right)[Value (€)], table.cell(align: right)[Probabilité], table.cell(align: right)[Rollout Date],),
  table.hline(),
  table.cell(align: horizon)[10], [polyconsiel], [Knox Suite EE], [€96,800.00], [B], [Q2 2025],
  table.cell(align: horizon)[14], [Burger King], [Knox Manage], [€62,190.00], [B], [Q2 2025],
  table.cell(align: horizon)[3], [Mondial Tissu], [Knox Suite EE], [€52,800.00], [B], [Q2 2025],
  table.cell(align: horizon)[0], [Penbase], [Knox Manage], [€39,590.00], [A], [Q1 2025],
  table.cell(align: horizon)[12], [Editis], [Knox suite EE], [€28,160.00], [N/A], [NaN],
)
#v(-20pt)
#block[
#block[

#horizontalrule

#figure([
#box(image("report_files/figure-typst/cell-15-output-1.png"))
], caption: figure.caption(
position: bottom, 
[
Figure 6: Top 5 SMB Pipeline Deals
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#v(-20pt)
#block[
]
#grid(
columns: (33.3%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[

#horizontalrule

],
)
] <firstcol>
]
] <firstcol>
]
] <firstcol>
]
] <firstcol>
]
] <firstcol>
]
] <firstcol>
]
] <firstcol>
]
] <firstcol>
]




