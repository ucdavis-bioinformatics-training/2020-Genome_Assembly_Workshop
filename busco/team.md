### Team Instructions

### Part 1 (20 minutes)

1. Choose someone from the group to be the team lead and communicator. This person will be responsible for posting team results to the appropriate Slack thread, collating the results, and presenting them to the group.

1. Generate assembly statistics for the two genome assemblies you have been assigned. Paste these into the Slack thread for your team. Make sure to label them clearly with the contig set!

1. Discuss the assembly statistics as a group. Form some hypotheses about which assembly will produce better BUSCO scores. What are you expectations for a Drosophila genome? What do you know about how the assembly was done?

1. As a team, figure out the proper commands for running BUSCO on the two assemblies assigned to your team. 
    * Use the "--lineage_dataset" option to speed up analysis. Paste your solution into the Slack chat under your team's thread. Make sure to label them clearly in the chat!
    * 

1. Designate two people in your group to run BUSCO. Assign one assembly to each.

1. Use srun to start an interactive session with 40 CPU cores and 32 gigs of RAM. Start BUSCO and make sure that it is running correctly.

-------

### Start Part 2 (10 minutes)

1. Once BUSCO has finished, paste the full path to the BUSCO results to your group's slack channel.

1. Aggregate the "short_summary.*" files from both of your contig sets. Make a BUSCO plot.

1. Prepare a short presentation (~3 slides, 5 minutes) with your observations about the assembly statistics and BUSCO results.


### Extra Credit Part 3 (?? minutes)

1. Go through the Slack threads for each team, collate paths to the BUSCO results from all of the contig sets.

1. Copy the "short_summary.*" files from all of these into a single folder, make a BUSCO plot. 

1. Which assembler (or assembly strategy) did the best?