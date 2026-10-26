# Set up an AWS Free Tier account and unlock $200 in credits

Follow this checklist to open a new AWS account on the Free Tier and collect all of the credits AWS offers new customers: **$100 when you sign up, plus up to $100 more for five short activities**. Then use them to run a Zetaris cluster in [Managed AWS cluster](managed-aws-cluster-guide.md).

Checked against AWS's own pages on 2026-10-20. AWS has changed this program before, so treat [AWS's pages](#sources) as the authority and follow their links for the current screens and terms.

> **Already have an AWS account?** The credits are for new AWS customers, so they do not apply to an account you already use. You can still install a small Zetaris cluster in it, but AWS bills that account at its normal prices. To use the free credits, open a new account by following this checklist.

## Before you start

- [ ] You are opening a **new** AWS account for this. AWS's credits are for new customers with accounts opened after 15 July 2025, and AWS gives Free Tier credits for only one account.
- [ ] You can receive email at the address you will use. Have a payment method ready if AWS's sign-up asks for one.
- [ ] You will **not** add this account to an AWS Organization, AWS Control Tower or the AWS Partner Network. Doing that upgrades a Free plan to a Paid plan, and AWS's terms say that after joining an Organization you can no longer use or earn Free Tier credits.

## 1. Create the account and choose the Free plan

> **Use the standard email/password signup for Zetaris:** open [AWS Sign up (advanced)](https://signin.aws.amazon.com/signup?request_type=register). The form should ask for a **Root user email address**. Avoid the new **Continue with Google** signup flow for this setup.

- [ ] Open [the direct AWS signup page](https://signin.aws.amazon.com/signup?request_type=register) and complete the email/password account setup.
- [ ] When AWS asks you to choose a plan, choose the **Free plan**. The Free plan means AWS does not charge you while you use it; the alternative, the Paid plan, bills anything beyond your credits. AWS explains the difference in [Choosing a plan](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html).
- [ ] Finish AWS's sign-up and sign in to the AWS Management Console.

## 2. Secure the account and add a cost alert

- [ ] Turn on multi-factor authentication for the root user: [AWS: MFA for the root user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user_manage_mfa.html).
- [ ] Create a cost budget that emails you when spending passes an amount you choose: [AWS: creating a budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html). This is also the fifth credit activity below.

## 3. Earn the extra $100 in credits

AWS gives **$20 for each of five activities**, up to $100. Credits can take **up to 10 minutes** to appear after you finish an activity, and AWS's announcement states no deadline for earning them. The activities are described here in AWS's words; follow the linked AWS page for the steps.

- [ ] **Amazon EC2 ($20):** launch an EC2 instance, then terminate it. [AWS: launch an instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html). Done when the instance shows as terminated.
- [ ] **Amazon RDS ($20):** learn the basic configuration options for launching an RDS database. [AWS: getting started with RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.html). If you create a database while doing this, delete it afterwards.
- [ ] **AWS Lambda ($20):** build a simple web app with a Lambda function that has a function URL. [AWS: Lambda function URLs](https://docs.aws.amazon.com/lambda/latest/dg/urls-configuration.html). Delete the function when you are done.
- [ ] **Amazon Bedrock ($20):** submit a prompt in the Bedrock text playground. [AWS: Bedrock playgrounds](https://docs.aws.amazon.com/bedrock/latest/userguide/playgrounds.html).
- [ ] **AWS Budgets ($20):** set up a cost budget. This is the budget from step 2, if you created it through AWS Budgets.

AWS describes all five in its [announcement](https://aws.amazon.com/blogs/aws/aws-free-tier-update-new-customers-can-get-started-and-explore-aws-with-up-to-200-in-credits).

## 4. Check that you have $200

- [ ] Open the [Billing and Cost Management console](https://console.aws.amazon.com/costmanagement/). It shows your credit balance and your Free plan information.
- [ ] Check that the balance is $100 from sign-up plus $20 for each activity you finished, up to **$200** in total. If an activity's credit is missing after 10 minutes, repeat the check, then see [If something looks wrong](#if-something-looks-wrong).
- [ ] Write down the plan end date. AWS emails you 15, 7 and 2 days before it, and you can also set a calendar reminder.

## 5. Know the limits

- **The Free plan ends after six months, or when your credits are used, whichever comes first.** AWS then closes the account. It keeps your content for 90 days, and you can upgrade to a Paid plan within those 90 days to keep the account. Any remaining credits then apply to your future bills.
- **Credits expire 12 months after the date you opened the account.**
- The Free plan does not include some services that could use up credits quickly, such as Savings Plans and Reserved Instances. It is not eligible for other promotional credits, and AWS says not to use it for sensitive data.
- Anything you leave running uses credits, including storage after you delete a cluster. Delete what you no longer need.

## 6. Install Zetaris on AWS

- [ ] Install on AWS by following [Managed AWS cluster](managed-aws-cluster-guide.md). In Zetaris testing, a Mini cluster running non-stop for about a week used roughly $80 of the credits, so a five-day event fits comfortably within $200. Your usage depends on the region and how long you leave it running, so check the balance as you go.
- [ ] If you would like to explore installation options, such as running Zetaris on your own computer instead or as well, see [Choose an install](choose-install.md).

## If something looks wrong

- **You used Google signup and Zetaris cannot verify the AWS account.** Follow [AWS account remains Unverified](../guides/troubleshooting.md#aws-account-remains-unverified). For a new setup, use the standard email/password signup linked above, then repeat Zetaris Quickstart in that account. A new account does not guarantee eligibility for additional Free Tier credits.
- **A credit has not appeared.** Wait the full 10 minutes, refresh the Billing and Cost Management console, and check that you completed the activity as AWS describes it on the linked page.
- **AWS says your plan was upgraded.** Joining an AWS Organization, Control Tower or the Partner Network upgrades the account to a Paid plan, which AWS bills at normal prices beyond any credits. AWS's terms say that after joining an Organization you can no longer use or earn Free Tier credits, so avoid it.
- **Your account was closed.** This follows the end of the Free plan. You have 90 days to upgrade and reopen it; after that AWS deletes the account's content.

## Sources

- [AWS Sign up (advanced): direct email/password signup](https://signin.aws.amazon.com/signup?request_type=register)
- [AWS sign-in options](https://docs.aws.amazon.com/signin/latest/userguide/what-is-sign-in.html)
- [AWS Free Tier](https://aws.amazon.com/free)
- [Choosing a plan (AWS Billing)](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html)
- [AWS Free Tier update: up to $200 in credits (AWS News Blog)](https://aws.amazon.com/blogs/aws/aws-free-tier-update-new-customers-can-get-started-and-explore-aws-with-up-to-200-in-credits)
- [AWS Free Tier terms](https://aws.amazon.com/free/terms)
- [Tracking your AWS Free Tier usage](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/tracking-free-tier-usage.html)
