name "ceph-osd"
description "Ceph Object Storage Device"
run_list(
        'recipe[ceph::repo]',
        'recipe[ceph::osd]'
)
