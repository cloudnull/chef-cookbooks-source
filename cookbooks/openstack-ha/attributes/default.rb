# mysql
# default["vips"]["config"]["127.0.0.2"]["vrid"]=10

# rabbitmq
# default["vips"]["config"]["127.0.0.3"]["vrid"]=11

#  all openstack services via haproxy
# default["vips"]["config"]["127.0.0.4"]["network"]="management"
# default["vips"]["config"]["127.0.0.4"]["vrid"]=12

default["apipa"] = "169.254.123.1"

default["vips"]["mysql-db"] = nil
default["vips"]["rabbitmq-queue"] = nil
default["vips"]["horizon-dash"] = nil
default["vips"]["horizon-dash_ssl"] = nil
default["vips"]["keystone-service-api"] = nil
default["vips"]["keystone-admin-api"] = nil
default["vips"]["keystone-internal-api"] = nil
default["vips"]["nova-xvpvnc-proxy"] = nil
default["vips"]["nova-api"] = nil
default["vips"]["nova-api-metadata"] = nil
default["vips"]["nova-ec2-public"] = nil
default["vips"]["nova-novnc-proxy"] = nil
default["vips"]["glance-api"] = nil
default["vips"]["glance-registry"] = nil
default["vips"]["cinder-api"] = nil
default["vips"]["neutron-api"] = nil
default["vips"]["ceilometer-api"] = nil
default["vips"]["ceilometer-central-agent"] = nil
default["vips"]["heat-api"] = nil
default["vips"]["heat-api-cfn"] = nil
default["vips"]["heat-api-cloudwatch"] = nil

# List of services we want to ignore when creating keystone endpoints
default["ha"]["service_ignore_list"] = ['glance-registry',
                                        'nova-api-metadata',
                                        'nova-xvpvnc-proxy',
                                        'nova-novnc-proxy',
                                        'horizon-dash',
                                        'horizon-dash_ssl',
                                        'heat-api-cloudwatch',
                                        'ceilometer-central-agent']

default["ha"]["available_services"]["keystone-admin-api"] = {
    "role" => "keystone-api",
    "namespace" => "keystone",
    "service" => "admin-api",
    "service_type" => "identity",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["keystone-service-api"] = {
    "role" => "keystone-api",
    "namespace" => "keystone",
    "service" => "service-api",
    "service_type" => "identity",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["keystone-internal-api"] = {
    "role" => "keystone-api",
    "namespace" => "keystone",
    "service" => "internal-api",
    "service_type" => "identity",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["nova-api"] = {
    "role" => "nova-api-os-compute",
    "namespace" => "nova",
    "service" => "api",
    "service_type" => "compute",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["nova-api-metadata"] = {
    "role" => "nova-api-metadata",
    "namespace" => "nova",
    "service" => "api-metadata",
    "service_type" => "metadata",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["nova-ec2-public"] = {
    "role" => "nova-api-ec2",
    "namespace" => "nova",
    "service" => "ec2-public",
    "service_type" => "ec2",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["cinder-api"] = {
    "role" => "cinder-api",
    "namespace" => "cinder",
    "service" => "api",
    "service_type" => "volume",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["glance-api"] = {
    "role" => "glance-api",
    "namespace" => "glance",
    "service" => "api",
    "service_type" => "image",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["swift-proxy"] = {
    "role" => "swift-proxy-server",
    "namespace" => "swift",
    "service" => "proxy",
    "service_type" => "object-store",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["glance-registry"] = {
    "role" => "glance-registry",
    "namespace" => "glance",
    "service" => "registry",
    "service_type" => "image",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["nova-novnc-proxy"] = {
    "role" => "nova-vncproxy",
    "namespace" => "nova",
    "service" => "novnc-proxy",
    "service_type" => "compute",
    "lb_mode" => "tcp",
    "lb_algorithm" => "source",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["nova-xvpvnc-proxy"] = {
    "role" => "nova-vncproxy",
    "namespace" => "nova",
    "service" => "xvpvnc-proxy",
    "service_type" => "compute",
    "lb_mode" => "tcp",
    "lb_algorithm" => "source",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["horizon-dash"] = {
    "role" => "horizon-server",
    "namespace" => "horizon",
    "service" => "dash",
    "service_type" => "dash",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["horizon-dash_ssl"] = {
    "role" => "horizon-server",
    "namespace" => "horizon",
    "service" => "dash_ssl",
    "service_type" => "dash",
    "lb_mode" => "tcp",
    "lb_algorithm" => "source",
    "lb_options" => ["ssl-hello-chk"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["ceilometer-api"] = {
    "role" => "ceilometer-api",
    "namespace" => "ceilometer",
    "service" => "api",
    "service_type" => "metering",
    "lb_mode" => "tcp",
    "lb_algorithm" => "source",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["ceilometer-central-agent"] = {
    "role" => "ceilometer-central-agent",
    "namespace" => "ceilometer",
    "service" => "central",
    "service_type" => "metering",
    "lb_mode" => "tcp",
    "lb_algorithm" => "source",
    "lb_options" => [],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["heat-api"] = {
    "role" => "heat-api",
    "namespace" => "heat",
    "service" => "base_api",
    "service_type" => "orchestration",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["heat-api-cfn"] = {
    "role" => "heat-api-cfn",
    "namespace" => "heat",
    "service" => "cfn_api",
    "service_type" => "cloudformation",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}
default["ha"]["available_services"]["heat-api-cloudwatch"] = {
    "role" => "heat-api-cloudwatch",
    "namespace" => "heat",
    "service" => "cloudwatch_api",
    "service_type" => "cloudwatch",
    "lb_mode" => "http",
    "lb_algorithm" => "roundrobin",
    "lb_options" => ["forwardfor", "httpchk", "httplog"],
    "ssl_lb_options" => ["ssl-hello-chk"]
}


if node["nova"]["network"]["provider"] == "neutron"
    default["ha"]["available_services"]["neutron-server"] = {
        "role" => "nova-network-controller",
        "namespace" => "neutron",
        "service" => "api",
        "service_type" => "network",
        "lb_mode" => "http",
        "lb_algorithm" => "roundrobin",
        "lb_options" => ["forwardfor", "httpchk", "httplog"],
        "ssl_lb_options" => ["ssl-hello-chk"],
    }
end

default['ha']['swift-only'] = false
