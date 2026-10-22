# AWS Batch Failure Map

| Symptom | Check first | Common fix |
|---|---|---|
| job remains `RUNNABLE` | Batch status reason, subnet egress, vCPU ceiling | use a subnet with NAT/public egress; raise `MaxvCpus` carefully |
| `AccessDenied` for S3 | job role and bucket region | grant only required bucket/prefix actions; keep resources in one region |
| image pull failure | image URI and CPU architecture | use a public/ECR image supporting the compute architecture |
| Nextflow cannot submit | coordinator identity | grant Batch submit/describe/terminate permissions to the caller |
| task lost on Spot | Nextflow trace and exit status | use `-resume`, bounded retries, or On-Demand for long non-checkpointed jobs |
| unexpectedly high S3 cost | work prefix and lifecycle | expire disposable work data; retain final outputs elsewhere |

Never solve an IAM error by attaching administrator access. Read the denied action and resource, then add the narrow permission required.
