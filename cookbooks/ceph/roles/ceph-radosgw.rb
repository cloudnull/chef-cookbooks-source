name "ceph-radosgw"
description "Ceph RADOS Gateway"
run_list(
        'recipe[ceph::repo]',
        'recipe[ceph::radosgw]'
)
