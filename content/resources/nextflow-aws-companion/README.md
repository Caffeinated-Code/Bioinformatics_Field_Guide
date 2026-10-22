# Companion Resources: Workflow Managers And Nextflow On AWS

These files support the cloud companion guide comparing workflow managers and introducing a tiny AWS Batch learning run for Nextflow.

| File | Purpose |
|---|---|
| `workflow-manager-decision-matrix.md` | Quick comparison of Nextflow, Snakemake, WDL/Cromwell, CWL, and Bash |
| `nextflow-aws-demo-main.nf` | Tiny Nextflow pipeline for local and AWS Batch connectivity testing |
| `nextflow-aws-demo.config` | AWS Batch profile template values to customize |
| `aws-cost-checklist.md` | Cost and cleanup checklist before running cloud workflows |
| `aws-batch-learning-stack.yml` | Bounded Fargate/Fargate Spot Batch environment with encrypted S3 work storage |
| `Dockerfile.aws-batch-demo` | Small Nextflow-compatible task image with Bash, `ps`, and AWS CLI v2 for S3 staging |
| `aws-troubleshooting.md` | Failure symptoms, diagnostics, and corrective actions |

Replace every `YOUR_*` value before attempting an AWS run.

The CloudFormation stack requires a VPC, subnets with outbound access, and a security group. It caps the learning environment at four Spot vCPUs and two On-Demand vCPUs, and creates an ECR repository for the demo image. The S3 bucket is retained during stack deletion to prevent accidental data loss; empty and delete it manually only after checking its contents.

AWS Batch tasks using an S3 work directory need the AWS CLI inside each task image unless you deliberately configure Wave and Fusion or an EC2 host installation. The supplied image includes it and keeps `/bin/bash` available to Nextflow.
