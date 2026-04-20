# AngloPlat CCE
We will be using the Simplified Branching Workflow (Section 6.3 of Git Ramp-up)

Please see `REMOVE_BEFORE_FLIGHT.txt` files in each folder for specific details regarding the intended contents of that folder.

## Branching Rules
* All feature dev work must be done on `feature/<component>`
* Each component is reasonably well isolated in the architecture, and uses other components only as a client. Talk to Dean if this doesn’t happen in practice.
* Don’t delete your branch; tag it when you’ve completed some milestone. (We want to learn from this large project implementation.)

## Merging Rules
* Don’t merge anything that doesn’t work back to main.
* Before merging your feature to main, merge main to your feature branch and test.
* Feel free to merge from other feature branches if you need a component.

## Testing
* Test/CI workflows don’t exist yet, so work on “How to test this” while you work on the feature. 
* It’s okay to have an interactive acceptance test.

## Repo Structure
* Design documentation is not part of the repo! The repo includes a link to the Project folder in Sharepoint.
* `/doc` contains deliverable documentation (technical documentation, user manuals, how-tos).
* `/test` contains test code and test artefacts (documents).
* Anything that runs CCE components in MATLAB is in the `/cce` folder.
	* Can have sub-folders for a component (cce/coordinator)
* `/build` contains anything that must be built
	* .Net interface classes, ProdServer calculations, etc.
	* Can have sub-folders for a component (build/netPiListener)
	* Must have a command-line build instruction in the build folder
