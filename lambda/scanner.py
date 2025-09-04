import boto3

def check_public_s3_buckets():
    s3 = boto3.client('s3')
    buckets = s3.list_buckets()['Buckets']
    public_buckets = []
    for bucket in buckets:
        acl = s3.get_bucket_acl(Bucket=bucket['Name'])
        for grant in acl['Grants']:
            if grant['Grantee'].get('URI') == 'http://acs.amazonaws.com/groups/global/AllUsers':
                public_buckets.append(bucket['Name'])
    return public_buckets

def check_security_groups():
    ec2 = boto3.client('ec2')
    sg_data = ec2.describe_security_groups()['SecurityGroups']
    open_sgs = []
    for sg in sg_data:
        for perm in sg.get('IpPermissions', []):
            for ip_range in perm.get('IpRanges', []):
                if ip_range['CidrIp'] == '0.0.0.0/0':
                    open_sgs.append(sg['GroupId'])
    return open_sgs

def check_iam_mfa():
    iam = boto3.client('iam')
    users = iam.list_users()['Users']
    non_mfa_users = []

    for user in users:
        user_name = user['UserName']
        mfa_devices = iam.list_mfa_devices(UserName=user_name)['MFADevices']
        login_profile = None
        try:
            login_profile = iam.get_login_profile(UserName=user_name)
        except iam.exceptions.NoSuchEntityException:
            pass  # User has no console access

        if login_profile and len(mfa_devices) == 0:
            non_mfa_users.append(user_name)

    return non_mfa_users

def check_cloudtrail():
    ct = boto3.client('cloudtrail')
    trails = ct.describe_trails()['trailList']
    missing_trails = []

    if not trails:
        return ["No CloudTrail found"]

    for trail in trails:
        if not trail.get('S3BucketName'):
            missing_trails.append(trail['Name'])

    return missing_trails
def check_iam_policies():
    iam = boto3.client('iam')
    risky_users = []
    
    users = iam.list_users()['Users']
    for user in users:
        policies = iam.list_attached_user_policies(UserName=user['UserName'])['AttachedPolicies']
        for policy in policies:
            policy_detail = iam.get_policy(PolicyArn=policy['PolicyArn'])['Policy']
            default_version = iam.get_policy_version(
                PolicyArn=policy['PolicyArn'],
                VersionId=policy_detail['DefaultVersionId']
            )['PolicyVersion']
            statements = default_version['Document']['Statement']
            for stmt in statements if isinstance(statements, list) else [statements]:
                if stmt.get('Effect') == 'Allow' and stmt.get('Action') == '*' and stmt.get('Resource') == '*':
                    risky_users.append(user['UserName'])
    return risky_users

def check_public_rds():
    rds = boto3.client('rds')
    instances = rds.describe_db_instances()['DBInstances']
    public_rds = []
    for db in instances:
        if db.get('PubliclyAccessible', False):
            public_rds.append(db['DBInstanceIdentifier'])
    return public_rds


if __name__ == "__main__":
    print("Public Buckets:", check_public_s3_buckets())
    print("Open Security Groups:", check_security_groups())
