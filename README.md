# Multi-AZ network optimized solution

In this lab, you will learn how to build **Multi-AZ network optimized solution** with the features described in the [Automate and Optimise SAP Network Performance in a Multi-AZ deployment](https://quip-amazon.com/cWW0A5ofzPsn/) blog and test in your system in less than an hour. 

Prerequisites:

* This solution was successfully tested on above S/4HANA 2022.
* To modify Logon groups and RFC server groups(RZ12), this solution will use SMLG_MODIFY function module.
* To modify Background processing groups (SM61), this solution will uses CL_BP_SERVER_GROUP class.
* It also includes the ability to push messages to Amazon SNS using the [AWS SDK for SAP ABAP](https://aws.amazon.com/blogs/awsforsap/getting-started-with-aws-sdk-for-sap-abap/) to notify BC admins of alerts via email or SNS.

Here is the overall architecture in this solution

![0.overall-architecture](./readmeImage/0.overall-architecture.png)

## 1. Create operational tables

The solution uses two operational tables.

1. **ZTAWSMULTIDB** : Save the result of SQL execution of getting an active database hostname.
2. **ZTAWSMULTIAZ** : Save the configuration information of changing application servers each groups.

You can create tables also create **ZE_AWS_DBHOST**,**ZE_AWS_GROUPTYPE**,  data elements using a transaction via **SE11**. Please refer to the below pictures for table structures.

* ZTAWSMULTIDB Table
![1.ZTAWSMULTIDB](./readmeImage/1.ZTAWSMULTIDB.png)
* ZTAWSMULTIAZ Table
![2.ZTAWSMULTIAZ](./readmeImage/2.ZTAWSMULTIAZ.png)

## 2. Update operational tables

Before executing this solution, we need to update **ZTAWSMULTIAZ** table to meet our SAP system environment. The below table is a configuration to meet the overall architecture. If you want to meet your environment, After login AWS console, can check your system configuration [AWS EC2 console](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:)

* GROUPTYPE
    * '': Logon Group
    * 'B': Batch Group
    * 'S': RFC Server Group
* GROUPNAME : Logon/Batch/RFC Server Group name
* DBHOST : DB Hostname
* APHOSTS : Application server instance name.
    * **sappas**, **sapaas02** are same az with **sappridb(Database)**
    * **sapaas01**, **sapaas03** are same az with **sapsecdb(Database)**

![3.optables](./readmeImage/3.optables.png)

* You can insert rows like the upper table using a transaction via **SE16N**. Search **ZTAWSMULTIAZ** table and click the execute button. you can see the table data and also execute CRUD(Create, Read, Update, Delete) function.

![4.se16n](./readmeImage/4.se16n.png)


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

