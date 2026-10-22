# AWS Cost Checklist For First Nextflow Runs

Before running:

- Create an AWS Budget alert.
- Confirm whether the account is Free plan or Paid plan with credits.
- Use a tiny test workflow before real sequencing data.
- Keep S3 bucket, AWS Batch queue, and compute environment in the same region.
- Use Spot only for retry-safe tasks.
- Keep final outputs separate from the Nextflow `workDir`.

After running:

- Download or preserve final outputs.
- Delete AWS Batch compute resources if they were created only for learning.
- Remove temporary S3 work files when no longer needed.
- Check the AWS Billing dashboard the same day.
