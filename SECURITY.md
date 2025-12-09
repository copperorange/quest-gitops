# Security Configuration Notes

## Production Hardening Recommendations

### Items Not Implemented (Cost vs. Benefit for Demo)

1. **Load Balancer Internal-Only**
   - Current: `internal = false` (internet-facing)
   - Production: Set to `true` and use CloudFront/WAF
   - Reason not implemented: Demo needs public access

2. **Custom KMS Keys for Encryption**
   - Current: AWS-managed keys
   - Production: Customer-managed KMS keys for:
     - ECR repository encryption
     - CloudWatch log encryption  
     - S3 bucket encryption
   - Reason not implemented: Adds cost and complexity for demo

3. **S3 MFA Delete**
   - Current: Disabled
   - Production: Enable MFA delete for state bucket
   - Reason not implemented: Requires manual AWS Console configuration

4. **S3 Access Logging**
   - Current: Disabled
   - Production: Enable logging to separate audit bucket
   - Reason not implemented: Additional S3 costs for demo

5. **Restrict Public Subnet Auto-Assign**
   - Current: `map_public_ip_on_launch = true`
   - Production: `false` (use NAT Gateway for outbound)
   - Reason not implemented: Simplifies demo networking

6. **Security Group Egress Restrictions**
   - Current: ECS tasks can egress anywhere
   - Production: Restrict to specific services (RDS, APIs, etc.)
   - Reason not implemented: Demo doesn't have fixed downstream services

## Implemented Security Measures

✅ **ALB Invalid Header Dropping**
- `drop_invalid_header_fields = true`
- Protects against header injection attacks

✅ **ALB Egress Restrictions**
- ALB can only communicate with ECS task security group
- Prevents data exfiltration via ALB

✅ **ECS ContainerInsights**
- Enabled for performance monitoring and security auditing
- CloudWatch metrics for container-level visibility

✅ **TLS 1.2 Minimum**
- `ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"`
- Prevents downgrade attacks

✅ **ECR Image Scanning**
- `scan_on_push = true`
- Automatic vulnerability scanning

✅ **S3 Versioning & Encryption**
- Versioning enabled for state recovery
- Server-side encryption (AES256)

✅ **S3 Public Access Block** (for state bucket when managed)
- All public access blocked

## Security Group Rules Summary

**ALB Security Group:**
- Ingress: 80, 443 from internet (required for public demo)
- Egress: 3000 to ECS tasks only (restricted)

**ECS Tasks Security Group:**
- Ingress: 3000 from ALB only
- Egress: All (for pulling images, calling external APIs)

## Terraform State Security

State is stored in S3 with:
- Versioning (recover from corruption)
- Encryption at rest (AES256)
- Block public access (when state bucket managed by Terraform)

**Note:** For production, use remote state locking with DynamoDB.

## To Enable Full Production Hardening

1. Set `internal = true` in ALB
2. Add CloudFront distribution in front
3. Create KMS keys and reference in resources
4. Enable S3 access logging
5. Configure MFA delete manually
6. Use NAT Gateway for private subnets
7. Restrict ECS egress to specific CIDRs
