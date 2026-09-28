# ------------------------------------------------------------------------------
# The host's subnet
# ------------------------------------------------------------------------------
# The data volume must live in the host's availability zone. It takes the zone
# from the subnet, which already exists and never moves, not from the
# instance: a replacement instance's zone is unknown until it exists, and a
# volume cannot change zone, so taking it from the instance made every host
# replacement replace (and empty) the data volume too.
# ------------------------------------------------------------------------------

data "aws_subnet" "host" {
  id = var.subnet_id
}
