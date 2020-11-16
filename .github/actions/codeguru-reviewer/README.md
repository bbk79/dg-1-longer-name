# AWS CodeGuru Security Scanner Action

Amazon CodeGuru Reviewer is a developer tool powered by machine learning that provides intelligent recommendations for improving code quality. The Security scanner leverages automated reasoning and AWS’s years of security experience to improve your code security. It ensures that your code follows best practices for KMS, EC2 APIs and common Java crypto and TLS/SSL libraries. When the security detector discovers an issue, a recommendation for remediation is provided along with an explanation for why the code improvement is suggested, thereby enabling Security Engineers to focus on architectural and application-specific security best-practices. For more information, see [CodeGuru Security blog](https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/how-codeguru-reviewer-works.html).

## Inputs

### `src-root`

**Required** Path to Java source root e.g. src/main/java.

### `build-artifact`

**Required** Path to build artifact(s) (jar files).

## Example usage

```yaml
- name: Configure AWS credentials
- uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-2    #AWS region where you want to use CodeGuru

- name: AWS CodeGuru Reviewer
- uses: aws-actions/codeguru-reviewer@v1
  with:          
    src-root: src/main/java # Java source code root
    build-root: target # build artifact(s) directory

- name: Upload review result
- uses: github/codeql-action/upload-sarif@v1
  with:
    sarif_file: codeguru-results.sarif.json
```
