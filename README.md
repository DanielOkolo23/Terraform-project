<h2>  Terraform PROJECT create 3 EC2 instances and put them behind an Elastic Load Balancer</h2>
create 3 EC2 instances and put them behind an Elastic Load Balancer, Exports the public IP addresses of the 3 instances to a file called host-inventory
 Set it up with AWS Route53 within your terraform plan, then add an A record for subdomain terraform-test that points to your ELB IP address.
 Create an Ansible script that uses the host-inventory file Terraform created to install Apache, set timezone to Africa/Lagos and displays a simple HTML page that displays content to clearly identify on all 3 EC2 instances.
