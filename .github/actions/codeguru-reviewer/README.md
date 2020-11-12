# AWS CodeGuru Security Scanner Action

Amazon CodeGuru Reviewer is a developer tool powered by machine learning that provides intelligent recommendations for improving code quality. The Security scanner leverages automated reasoning and AWS’s years of security experience to improve your code security. It ensures that your code follows best practices for KMS, EC2 APIs and common Java crypto and TLS/SSL libraries. When the security detector discovers an issue, a recommendation for remediation is provided along with an explanation for why the code improvement is suggested, thereby enabling Security Engineers to focus on architectural and application-specific security best-practices. For more information, see [CodeGuru Security blog](https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/how-codeguru-reviewer-works.html).

## Environment Variables

### `AWS_ACCESS_KEY_ID`

**Required** AWS Access Key.

### `AWS_SECRET_ACCESS_KEY`

**Required** AWS Secret Access Key.

### `AWS_DEFAULT_REGION`

**Required** AWS Region.

## Inputs

### `src-root`

**Required** Path to Java source root e.g. src/main/java.

### `build-artifact`

**Required** Path to build artifact(s) (jar files).

## Example usage

```yaml
- name: AWS CodeGuru Reviewer
- uses: aws-actions/codeguru-reviewer@v1
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_DEFAULT_REGION: us-west-2 # AWS Region
  with:          
    src-root: src/main/java # Java source code root
    build-root: target # build artifact(s) directory

- name: Upload review result
- uses: github/codeql-action/upload-sarif@v1
  with:
    sarif_file: codeguru-results.sarif.json
```
