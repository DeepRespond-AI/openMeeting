"""OSS SDK operations shared by meeting audio and installer direct uploads."""
import asyncio


class OssDirectUpload:
    def presign_put(self, key, proof, content_type, expires):
        signer = getattr(self, "download_bucket", self.bucket)
        if "-internal.aliyuncs.com" in signer.endpoint:
            signer = self._oss2.Bucket(signer.auth, signer.endpoint.replace("-internal.aliyuncs.com", ".aliyuncs.com"),
                                       self.cfg.bucket, region=self.cfg.region)
        headers = {"Content-Type": content_type, "Content-MD5": proof.md5,
                   "x-oss-meta-sha256": proof.sha256, "x-oss-meta-content-md5": proof.md5,
                   "x-oss-server-side-encryption": "AES256"}
        return {"url": signer.sign_url("PUT", key, expires, headers=headers, slash_safe=True), "headers": headers}

    async def stat_object(self, key):
        try:
            stat = await asyncio.to_thread(self.bucket.head_object, key)
        except self._oss2.exceptions.NotFound as exc:
            # HEAD 404 has no XML body, so the SDK commonly raises plain NotFound.
            if isinstance(exc, self._oss2.exceptions.NoSuchBucket):
                raise
            return None
        return {"size": stat.content_length, "etag": stat.etag,
                "metadata": {k.lower().removeprefix("x-oss-meta-"): v for k, v in stat.headers.items()
                             if k.lower().startswith("x-oss-meta-")}}

    async def copy_object(self, source, target, etag):
        await asyncio.to_thread(self.bucket.copy_object, self.cfg.bucket, source, target,
                                headers={"x-oss-copy-source-if-match": etag, "x-oss-metadata-directive": "COPY",
                                         "x-oss-server-side-encryption": "AES256"})

    async def delete_object(self, key):
        await asyncio.to_thread(self.bucket.delete_object, key)
