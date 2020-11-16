#!/bin/sh

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

export AWS_DEFAULT_OUTPUT="text"

aws configure add-model --service-model file://codeguru-reviewer-2019-09-19.normal.json --service-name codeguru
cp codeguru-reviewer-2019-09-19.waiters-2.json ~/.aws/models/codeguru/2019-09-19/waiters-2.json

cmd="aws --endpoint https://us-west-2.gamma.fe-service.guru.aws.a2z.com codeguru"

clean_up () {
  if [ $should_clean_up ]
  then
    printf "\n${cyn}Cleaning up artifacts uploaded to S3...${end}\n";
    aws s3 rm --recursive s3://$bucketName/$path/
    [ ! $? -eq 0 ] && printf "\n${yel}Failed to delete artificats from S3.${end}\n";
    rm source.zip artifacts.zip
  fi
}

die () {
    echo >&2 "\n${red}Exiting with ERROR: $@${end}"
    clean_up
    exit 1
}

die_if_failed () {
    [ ! $? -eq 0 ] && die "Last operation failed."
}

[ ! $src_root ] && src_root=$1
[ ! $build_root ] && build_root=$2

[[ $GITHUB_REPOSITORY ]] && name=${GITHUB_REPOSITORY//\//-} || name=$CI_PROJECT_PATH_SLUG
[[ $GITHUB_SHA ]] && SHA=$GITHUB_SHA || SHA=$CI_COMMIT_SHA
path="${name}_${SHA}"

printf "\n${grn}AWS CodeGuru Reviewer Security Scanner Action${end}\n"
printf "\nassociation name: ${yel}$name${end}   region: ${yel}$AWS_DEFAULT_REGION${end}   src-root: ${yel}$src_root${end}   build-artifact: ${yel}$build_root${end}\n"

[ ! -d $build_root ] && die "Build artifact directory not found."
[ ! -d $src_root ] && die "Source root not found or is not a directory."
[ ! $SHA ] && die "Commit hash not set."
[ ! $name ] && die "Association name not set."

printf "\n${cyn}Querying for the repository association '$name'...${end}\n";

associationArn=$($cmd list-repository-associations --query "RepositoryAssociationSummaries[?ProviderType=='S3Bucket' && Name=='$name'].AssociationArn | [0]")
die_if_failed

if [ $associationArn == None ]
then
    printf "${cyn}No repository association found, creating a new association...${end}\n";
    associationArn=$($cmd associate-repository --repository "{\"S3Bucket\": {\"Name\": \"$name\"}}" --query RepositoryAssociation.AssociationArn)
    die_if_failed
    printf "\nassociation-arn: ${yel}$associationArn${end}\n"
    printf "${cyn}Awaiting association complete...${end}\n";
    $cmd wait association-complete --association-arn "$associationArn"
    die_if_failed
else
  printf "\nassociation-arn: ${yel}$associationArn${end}\n"
fi

bucketName=$($cmd describe-repository-association --association-arn "$associationArn" --query RepositoryAssociation.S3RepositoryDetails.BucketName)
die_if_failed

printf "S3 bucket name: ${yel}$bucketName${end}\n"

printf "\n${cyn}Archiving source...${end}\n";
zip -r source $src_root
die_if_failed

printf "\n${cyn}Archiving build artifacts...${end}\n";
zip -j artifacts $build_root/*.jar
die_if_failed

should_clean_up=true

printf "\n${cyn}Uploading source archive...${end}\n";
aws s3 cp source.zip s3://$bucketName/$path/
die_if_failed

printf "\n${cyn}Uploading the build artifact...${end}\n";
aws s3 cp artifacts.zip s3://$bucketName/$path/
die_if_failed

printf "\n${cyn}Submitting the review request...${end}\n";
CodeReviewArn=$($cmd create-code-review --name "${path}_$(date +%s)" --repository-association-arn "$associationArn" --type "{\"RepositoryAnalysis\": {\"S3BucketRepository\": {\"Name\": \"$name\",\"Details\": {\"BucketName\": \"$bucketName\",\"CodeArtifacts\": {\"BuildArtifactsObjectKey\": \"$path/artifacts.zip\", \"SourceCodeArtifactsObjectKey\": \"$path/source.zip\"}}}},\"AnalysisTypes\": [\"Security\"]}" --query CodeReview.CodeReviewArn)
die_if_failed

printf "\ncode-review-arn: ${yel}$CodeReviewArn${end}\n";
printf "\n${cyn}Awaiting results...${end}\n";
$cmd wait code-review-complete --code-review-arn $CodeReviewArn
if [ ! $? -eq 0 ]
then
  printf "\n${red}Timed out waiting for results or review failed.${end}\n";
else
  printf "\n${cyn}Fetching review results...${end}\n";
  $cmd --output json list-recommendations --code-review-arn $CodeReviewArn > codeguru-results.sarif.json
fi

clean_up

printf "\n${grn}End of Action${end}\n"
