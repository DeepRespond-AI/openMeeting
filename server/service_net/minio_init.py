"""一次性基础设施任务：仅创建私有 Bucket，不修改访问策略或清理已有对象。"""
import os

from minio import Minio
from minio.error import S3Error

from service_net.minio_store import endpoint_parts


def main():
    endpoint, secure = endpoint_parts(os.environ['OPENMEETING_MINIO_ENDPOINT'])
    client = Minio(endpoint, access_key=os.environ['OPENMEETING_MINIO_ACCESS_KEY_ID'],
                   secret_key=os.environ['OPENMEETING_MINIO_ACCESS_KEY_SECRET'], secure=secure,
                   region=os.environ.get('OPENMEETING_MINIO_REGION', 'us-east-1'))
    bucket = os.environ['OPENMEETING_MINIO_BUCKET']
    if not client.bucket_exists(bucket):
        try:
            client.make_bucket(bucket, location=os.environ.get('OPENMEETING_MINIO_REGION', 'us-east-1'))
        except S3Error as error:
            if error.code not in {'BucketAlreadyOwnedByYou', 'BucketAlreadyExists'}:
                raise
    print('MinIO private bucket is ready')


if __name__ == '__main__':
    main()
