# Specify the provider and access details
provider "ucloud" {
  region = "${var.region}"
}

# Query availability zone
data "ucloud_zones" "default" {}

# Query image
data "ucloud_images" "default" {
  availability_zone = "${data.ucloud_zones.default.zones.0.id}"
  name_regex        = "^CentOS 7.[1-2] 64"
  image_type        = "base"
}

# Create security group
resource "ucloud_security_group" "default" {
  name = "tf-example-eip"
  tag  = "tf-example"

  rules {
    port_range = "80"
    protocol   = "tcp"
    cidr_block = "192.168.0.0/16"
    policy     = "accept"
  }
}

# Create an eip
resource "ucloud_eip" "default" {
  bandwidth     = 2
  charge_mode   = "bandwidth"
  name          = "tf-example-eip-${format(var.count_format, count.index + 1)}"
  tag           = "tf-example"
  internet_type = "bgp"

  count = "${var.count}"
}

# Create a web server
resource "ucloud_instance" "web" {
  instance_type     = "n-standard-1"
  availability_zone = "${data.ucloud_zones.default.zones.0.id}"
  image_id          = "${data.ucloud_images.default.images.0.id}"

  data_disk_size = 50
  root_password  = "${var.instance_password}"
  security_group = "${ucloud_security_group.default.id}"

  name = "tf-example-eip-${format(var.count_format, count.index + 1)}"
  tag  = "tf-example"

  count = "${var.count}"
}

# Bind eip to instance
resource "ucloud_eip_association" "default" {
  resource_id = "${element(ucloud_instance.web.*.id, count.index)}"
  eip_id      = "${element(ucloud_eip.default.*.id, count.index)}"
  count       = "${var.count}"
}
