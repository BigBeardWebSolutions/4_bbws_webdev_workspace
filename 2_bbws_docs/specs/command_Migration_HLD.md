Follow TBT
Stage files in staging folder
Use Agent: agents/Agentic_Architect/agent.md
Create a plan first and let me confirm it.
I want to create an HLD in agents/Agentic_Architect/architectures/BBWS/HLDs/migration_hld
File name: BBWS_Migration_HLD.md
Ask me clarification questions for the requirements below by spittiing out a file named questions.md in agents/Agentic_Architect/architectures/BBWS/HLDs/migration_hld. 
I will answer any questions you have.
This is for a solution that will be implemented by BBWS on AWS that have the followng major components:
Solution Name: Site Migration HLD
Requirements overview:
Epic: Migrate a website from xneelo to my machine
- A python utility that pulls a website from a live URL and creates a copy of the site on my local machine
- This utility traverses the existing site folder structure and pulls the site as is and writes it ti a local directory.
Epic: Site Cleanup and verification
- This is a local python utility that cleans the files that have been pulled down by the SiteMigrator
- Site come down with hard-coded URL and Wordpress specific details that make site not to work locally
- This utility fixes all those defects and create a fully functional site(s)
Epic: Deploy Site to S3 and cloud front
- Create a directory on s3 for the site
- Push the cleaned site to S3
- Create an ACM certificate for the website to use on CF
- Configure S3 as the origin for CloudFront
Epic: Accept form submissions from site visitors
- This is a universal lambda that accepts JSON/REST/HTTP Posts from the sites and write to S3
- Writes to a DynamoBD table name Forms
- Send Emails to form/site owners notifying them of the submission
Component Overview: A set of components that are used to migrate, clean up and deploy sites to S3, AWS Certificate Manager,Cloud Front and DNS using XNeelo
- SiteMigrator - Pulls the site from the internet and writes it to the local file system
- SiteSiteCleaner - Fixes any quuicks with the website making sure it's ready for deployment
- SiteDeployer - Deploys the cleaned site by pushing it to S3
- CertificateManager - Creates a certificate on ACM associated with the prod domain of the customer and pre-prod domain. e.g. site.co.za - Prod prod.site.co.za Pre-prod
- CloudFrontManager - Sets S3 As origin for cloudfront and blocks direct S3 access from the public