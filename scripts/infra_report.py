#!/usr/bin/env python3
"""
Infra reporting script - supplementary to the Terraform/CloudFormation stacks.
Reports on EC2 instance state and S3 bucket security posture across the account.
Usage: python scripts/infra_report.py --region ap-south-1
"""
import argparse
import boto3
from datetime import datetime, timezone


def report_ec2(ec2_client):
    print("\n=== EC2 Instances ===")
    paginator = ec2_client.get_paginator("describe_instances")
    for page in paginator.paginate():
        for reservation in page["Reservations"]:
            for instance in reservation["Instances"]:
                name = next(
                    (t["Value"] for t in instance.get("Tags", []) if t["Key"] == "Name"),
                    "unnamed",
                )
                launch_time = instance["LaunchTime"]
                uptime_hours = (datetime.now(timezone.utc) - launch_time).total_seconds() / 3600
                print(
                    f"  {name:20s} {instance['InstanceId']:22s} "
                    f"{instance['State']['Name']:10s} "
                    f"{instance['InstanceType']:10s} "
                    f"uptime={uptime_hours:.1f}h"
                )


def report_s3(s3_client):
    print("\n=== S3 Buckets - Security Posture ===")
    buckets = s3_client.list_buckets()["Buckets"]
    for bucket in buckets:
        name = bucket["Name"]
        try:
            enc = s3_client.get_bucket_encryption(Bucket=name)
            encrypted = True
        except s3_client.exceptions.ClientError:
            encrypted = False

        try:
            pab = s3_client.get_public_access_block(Bucket=name)["PublicAccessBlockConfiguration"]
            public_blocked = all(pab.values())
        except s3_client.exceptions.ClientError:
            public_blocked = False

        status = "OK" if (encrypted and public_blocked) else "REVIEW NEEDED"
        print(f"  {name:45s} encrypted={encrypted!s:6s} public_blocked={public_blocked!s:6s} [{status}]")


def main():
    parser = argparse.ArgumentParser(description="Report on account infra state")
    parser.add_argument("--region", default="ap-south-1")
    args = parser.parse_args()

    ec2 = boto3.client("ec2", region_name=args.region)
    s3 = boto3.client("s3", region_name=args.region)

    print(f"Infra report - region={args.region} - generated {datetime.now(timezone.utc).isoformat()}")
    report_ec2(ec2)
    report_s3(s3)


if __name__ == "__main__":
    main()
