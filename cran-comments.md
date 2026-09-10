## Submission notes

This is a resubmission. The previous submission passed automated CRAN 
checks but was returned after manual review with the following requests, 
all of which have been addressed:

* Added a `References` field to DESCRIPTION, citing the methods paper 
  in the requested `authors (year) <doi:...>` format.

* Replaced `\dontrun{}` with `\donttest{}` in the examples for 
  `Regustab()` and `Convstab()`.

* `Regustab()` and `Convstab()` no longer use `print()`/`cat()` to 
  report results to the console. Both functions now return their 
  results (regularisation values, selection frequencies, and the plot 
  object) as a list, returned invisibly, which the user can inspect or 
  extract from.

* `Regustab()` now saves the user's graphical parameters with 
  `oldpar <- graphics::par(no.readonly = TRUE)` and restores them on 
  exit via `on.exit(graphics::par(oldpar))`, immediately before any 
  call that modifies `par()`.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE
  unable to verify current time

This NOTE is due to an inability to reach an internet time-check 
server in the local testing environment and is not related to the 
package itself.
