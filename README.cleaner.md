# Docker cleaner quick-start

## Create a list of applications to clean up

Put the list a file, in the format path/to/container. The hostname
component of the URI is irrelevant since we will specify that
explicitly when we invoke the cleaner script.

```
$ cat apps-to-clean.txt
avvo/account
avvo/amos
avvo/answer-quality-classifier
...
```

## Create a list of image tags to be excluded from clean-up

Typically this is done by scanning *all* of your clusters to get a list of any images that are in use in at least one pod:

```
$ ( for cluster in cluster1 cluster2 cluster3; do \
    kubectl get pods --context $cluster --all-namespaces -o json | \
      jq -r '.items[].spec.containers[].image'; \
  done ) | \
   sed 's#avvo-docker-local.artifactory.internetbrands.com/##g;' | \
   sort -u > exclude-tags.txt
```

Note the `sed` command for stripping out hostnames from the image tag strings that are retrieved.

The resulting file should look like this:

```
$ head exclude-tags.txt
avvo/account:0ed45b6e919d0977f2d0a6ec5c5f1ceee34f800f
avvo/amos:1e3b6c0e071a06d94dc3052d373f22ba1eba3def
avvo/amos:45a3ddafa0adf7ef8ebf9b7156e4a68aabd4a47a
...
```

## Run the bin/cleaner script

```
# Usage is:
#   bin/cleaner.rb [--actually-delete] [--delete-empty-path] \
#     artifactory_url \
#     repo_key \
#     username \
#     password \
#     application_list \
#     image_exclude_list \
#     days_to_keep \
#     [most_recent_images_to_keep] 

# Clean old container images of all of the apps listed in apps-to-clean.txt
# on https://artifactory.internetbrands.com in repo key avvo-docker-local, 
# excluding any tags in the recently-generated exclude-tags.txt, delete any
# images more # than 30 days old (but keep the most recent 10 image builds
# regardless of whether they are in use).

$ bin/cleaner.rb \
    https://artifactory.internetbrands.com \
    avvo-docker-local \
    jsmith \
    supersecret \
    apps-to-clean.txt \
    exclude-tags.txt \
    30 \
    10
```
