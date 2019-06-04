<?php
for ($i=1; $i<count($cfg['Servers']); $i++) {
    $cfg['Servers'][$i]['AllowNoPassword'] = true;
}
