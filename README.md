# ai-project-configuration
Configuration directories/systems for new project directories

This project is designed to hold my AI rules and workflows as well as project templates that I use regularly.

The AI rule and workflows are designed to use directories and files in the project template and be the "source of truth" for any AI I use.

I'm currently using Antigravity/Gemini, so these rules are geared toward that environment.  If you're using something else, you'll likely need to remove the yaml "description" from the workflows at the very least.

This is designed to be run on an Ubuntu/Mint machine, running the install on a Windoze machine is likely to be non-functional at best and catastrophic at worst.

After pulling down an update, run
scripts/init-gemini.sh

And run the init-py-project.sh script in each python repo you want to update
