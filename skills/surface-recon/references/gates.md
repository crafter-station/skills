# Gates

Checks that stop a recon from producing a confident, wrong report. Each one exists because it failed in real work.

## Before starting

**Did you search for an official API?** The cheapest recon is reading a spec. Search for docs, an OpenAPI file, and an SDK before opening a browser. Skipping this and going straight to traffic capture is the most common way to spend hours on a solved problem.

**Do you have credentials for a login-walled target?** If not, the output will be a list of unknowns, not a map. Say that before starting, and ask whether an account is obtainable. Six corpus reports skipped this gate and produced tables where 80 to 90 percent of rows were unverified.

**Is there a public path to the same data?** Many services with a login also expose a public consultation form or an open-data export. Check before accepting a credential-blocked recon.

## During capture

**Is the domain you captured where the functionality lives?**

This failed three separate times in the corpus. In each case the capture targeted an institutional landing page while the actual service ran on a different subdomain. The result was a HAR full of marketing pages and an endpoint table full of nothing.

Verify: the URL in your capture should be the one that serves the action you care about. If you captured a page listing links to services, you captured the directory, not the service.

**Did you drive the actual action?** Endpoints appear on interaction, not on page load. A HAR from a bare `open` shows you the shell.

**Is a state you classified stable across calls?** Ask for the same resource twice. A value that differs between responses is not an attribute of the resource, and filing it next to the stable ones makes the client treat it as fixed. In one recon a seat state mapped as one of eight statuses turned out to be the seat the provider pre-assigns to each transaction: three orders on the same session returned three different seats. It went from a curious color to the default suggestion for the reserve command, and only because someone asked what it was.

**Did you reproduce without credentials before blaming your account?** A failure that persists with no identity is not about your identity. To separate "they blocked me" from "it is down for everyone", drop the session: public reads still returning 200 rules out an IP block, an endpoint answering 401 before its suspension message shows the session filter runs first, and a clean browser reaching the normal login panel rules out a ban.

**A flow captured with a browser is not verified until you replay it without one.** The browser sends cookies by domain, follows redirects, and holds state, so a HAR records the outcome rather than the requirement. Phase 3 already says to replay a signature outside the browser; this generalizes it to the whole flow. Two first-use failures in one project had exactly this root: a cookie prefix and a required header, both invisible in the capture because the browser supplied them.

**An endpoint you assembled from bundle strings is not an endpoint.** A route built out of grepped constants is a guess, and a 404 page served under HTTP 200 will confirm it for you. On the first real run of this skill, four attempts were burned this way. Either the request appears in traffic you drove, or it goes under "Needs verification" with the interaction that would produce it. There is no third category.

**Did you keep the evidence?** A finding whose HAR is gone cannot be re-verified. One corpus report claimed a recon technique had been used but the repository preserved no receipt, so the claim had to be re-derived from scratch. Save the HAR. Note the bundle hash if you read a bundle.

## Before writing a finding

Apply these per row of the endpoint table.

**Did you observe this request, or infer it?** Observed means you saw it in traffic or reproduced it. Inferred means you read it in a bundle, guessed from a naming pattern, or found it in stale docs. Both are useful. Mixing them silently is not. Mark the column.

**Did you verify the auth flow, or read it?** An auth flow you have not completed is a hypothesis. Especially true for anything involving a second factor, a certificate, or a signature.

**If you extracted a signing algorithm, did you replay it?** A signing function read from minified code and never exercised is a guess with high confidence attached. Replay a signed request from outside the browser. The corpus case that did this discovered the signed message included fields nobody would have predicted; only the replay proved the shape.

**Did you parse the response body, or trust the status code?** One login endpoint returned 200 for a wrong password, with the real outcome in a JSON field. Never conclude success from a status code alone on an endpoint you are characterizing.

**Are you reporting a rate limit you measured?** If you did not read a header or probe, write "not measured".

## Before claiming a hardware finding

**Did you verify where the work ran, or only that it did not error?** A device rarely refuses. It accepts the workload and quietly runs it on a slower unit. Absence of an error is not evidence of acceleration. Measure per compute unit.

**Is your constraint set measured or cited?** A published characterization is a citation and belongs marked as one. What you exported, ran, and counted is your finding. Keeping them separate is what stops someone else's claim from becoming your unverified assumption.

**Did you record the silicon, OS, and toolchain version?** A constraint true on one generation can be false on the next, and a report without those three cannot be re-checked.

**Did you compare against a baseline on the same machine?** "Faster" with no same-size comparison under the same load is not a measurement.

## Before claiming a backend type

**Do not infer the stack from route names.** One endpoint named for one cloud provider served a completely different one, a leftover from a migration. Names lie. Infer the backend from response headers, error formats, and framework tells; or write "not determined".

## Before delivering

**Does the report distinguish what you know from what you assume?** Read it once as an implementer. Every line they would act on should be traceable to an observation.

**Is the verdict stated?** "Build it", "build it narrowly", or "do not build yet, blocked on X". A report without a recommendation makes the reader redo your judgment.

**Is the maintenance risk named?** An undocumented endpoint has no contract and no deprecation notice. If the plan depends on a minified signing function, a coordinate-clicked widget, or a scraped HTML structure, say that it will break. Roughly when, if you can tell.

**Are the "needs verification" items actionable?** Each should say what would confirm it, not just that it is unconfirmed.

## The failure this all prevents

A recon report that reads as authoritative and is partly invention. The implementer builds against it, discovers the auth flow was never completed and half the endpoints do not exist, and now distrusts the whole document: including the parts that were correct and hard-won.

Labeling uncertainty costs one column in a table. Losing the reader's trust costs the entire report.
