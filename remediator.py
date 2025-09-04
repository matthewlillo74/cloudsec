import boto3

def fix_public_s3(bucket_name):
    s3 = boto3.client('s3')
    s3.put_bucket_acl(Bucket=bucket_name, ACL='private')
    print(f"Bucket {bucket_name} set to private.")

def fix_open_sg(sg_id):
    ec2 = boto3.client('ec2')
    sg = ec2.describe_security_groups(GroupIds=[sg_id])['SecurityGroups'][0]

    for perm in sg['IpPermissions']:
        for ip_range in perm.get('IpRanges', []):
            if ip_range['CidrIp'] == '0.0.0.0/0':
                # Remove this specific rule
                ec2.revoke_security_group_ingress(
                    GroupId=sg_id,
                    IpPermissions=[perm]
                )
                print(f"Removed open access from {sg_id}")

def recommend_mfa(user_name):
    return f"Enable MFA for user {user_name}. This cannot be automated via API; requires user action."

def recommend_fix_iam_policy(user_name):
    return f"Review and restrict policies for user {user_name}. Avoid wildcard permissions (*:*)"

def fix_public_rds(db_identifier):
    rds = boto3.client('rds')
    rds.modify_db_instance(
        DBInstanceIdentifier=db_identifier,
        PubliclyAccessible=False,
        ApplyImmediately=True
    )
    print(f"Modified RDS {db_identifier} to be non-public.")
