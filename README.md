# s3-terraform-portfolio-project
Static Portfolio Website Hosted on S3 with Terraform

## Overview
This project provides a guide on how to deploy a static website on S3 using Terraform. With Terraform, we would create an S3 bucket and make it public, along with a page for error handling.


### Why Terraform?
Terraform has proven itself to be a very useful IaC tool in the Cloud and DevOps Engineering ecosystem.

The key advantage of using Terraform is that it allows for infrastructure to be managed as code, enabling automation, reusability, and collaboration across different cloud providers and environments. It simplifies the process of provisioning, managing, and updating infrastructure, making it faster and more efficient. 

### Project Pre-requisites

- An active AWS account.
- Terraform Installation Completed.

### Project Steps


```
s3-portfolio-website/
├── index.html
├── error.html
├── terraform/
│   ├── provider.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
└── profile.jpg  <-- Add your image here

```

----

#### Set Up Provider on Terraform

The first thing we would do is set up our provider. You can run `terraform init` after that to download the provider plugin and initialize the backend for state management.

```
# provider.tf

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

```

-----

#### Set Up S3 Bucket with Terraform

The resource block below creates a bucket with `bucket` as a required field specifying the name of the bucket being created.

```
#main.tf

resource "aws_s3_bucket" "sitebucket" {
  bucket = var.bucketname
}

```
The `variables.tf` file is used to define your variables instead of hard-coding them in the `main.tf` file. This is best practice.

```
#variables.tf

variable "bucketname" {
  default = "<your-bucket-name>"
}

```

----

#### Set Up Bucket Ownership

This is to set ownership of the bucket and ensure no one else can claim ownership.

```
#main.tf

resource "aws_s3_bucket_ownership_controls" "objectOwner" {
  bucket = aws_s3_bucket.sitebucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

```

----

#### Make S3 Bucket Publicly Accessible

By default, AWS S3 buckets are private and restricted for public access, which follows AWS security's principle of Least Privilege. This is best practice as it minimizes the potential attack surface and reduces the risk of unauthorized access or data breaches.

However, to host the site through S3 and allow our website and images to be publicly accessible, we need to make the bucket public using the resource block below.

```
#main.tf

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.sitebucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucketacl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.objectOwner,
    aws_s3_bucket_public_access_block.public,
  ]

  bucket = aws_s3_bucket.sitebucket.id
  acl    = "public-read"
}

```

----

#### Set Up Site Files and Objects

This will upload your site files and images from your local environment to your S3 Bucket.

```
#main.tf

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitebucket.id
  key          = "index.html"
  source       = "../index.html"
  acl          = "public-read"
  content_type = "text/html"

  depends_on = [ aws_s3_bucket_acl.bucketacl ]

}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.sitebucket.id
  key          = "error.html"
  source       = "../index.html"
  acl          = "public-read"
  content_type = "text/html"

  depends_on = [ aws_s3_bucket_acl.bucketacl ]

}

resource "aws_s3_object" "profilepic" {
  bucket = aws_s3_bucket.sitebucket.id
  key    = "linkedin-profile-pic.jpeg"
  source = "../linkedin-profile-pic.jpeg"
  acl    = "public-read"

  depends_on = [ aws_s3_bucket_acl.bucketacl ]
}

```

----

#### Enable Static Website Hosting on S3

This resource block will help set up our website on S3, specifying the index and error files.

```
#main.tf

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.sitebucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  depends_on = [ aws_s3_bucket_acl.bucketacl ]

}

```
Note: The `depends_on` attribute is to let your code know the order in which you want your resource blocks created. In other words, it tells you the dependencies for your resource block, which means for the resource block above, the bucketacl resource must be created first before the website resource.

I created an `outputs.tf` file to return the value of my website endpoint on my terminal, as against getting it from the AWS console directly.

```
#outputs.tf

output "website_endpoint" {
  value = aws_s3_bucket.sitebucket.website_endpoint
}

```

We are now done with building the resource blocks. The next steps are to run the following commands to help us create the infrastructure in our AWS environment:

| Command       | Description |
| :----------- | ----------- |
| `terraform fmt` | Automatically formats your configuration files into a standard format that adheres to a predefined set of rules of indentation, spacing, and alignment across your terraform code, making it more readable and maintainable|
| `terraform validate` | Checks the Syntax and structure of your Terraform configuration files without deploying any resources. |
| `terraform plan` | Creates a plan consisting of the set of changes that will make your resources match your configuration |
| `terraform apply -auto-approve` | Executes the actions proposed in a Terraform plan to create, update, or destroy infrastructure. The `-auto-approve` option is to automatically approve, as `terraform apply` will always ask for confirmation of approval when it runs |

----

![Terraform codes](<img width="702" alt="image" src="https://github.com/user-attachments/assets/3a3e18ea-686c-4d3e-b117-ed1742920f9c" />
)


![Terraform codes 2](<img width="882" alt="image" src="https://github.com/user-attachments/assets/bcb2ff00-c3ec-42fa-87b4-40d5222dd1d5" />
)


![Terraform codes 3](<img width="775" alt="image" src="https://github.com/user-attachments/assets/1c0d2ed5-2605-4565-b90e-4a4f2c544bc2" />
)


----

After the commands have been run, your website should be up with the endpoint made available to you on your terminal for confirmation.

![S3 Site Deployed](<img width="1251" alt="image" src="https://github.com/user-attachments/assets/d1f01095-b839-4fe9-8965-744fe4264f4f" />
)




Note: If you come across this error: `Error: uploading object to S3 bucket : AccessControlListNotSupported: The bucket does not allow ACLs status code: 400`, Ensure you use the `depends_on` attribute to ensure that your bucket ACL is configured first for public-read before the files are uploaded.

On a final note, you can always refer to the [Terraform Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) to assist you build your infrastructure.


