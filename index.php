Auto Launching of Webserver using Terraform 
<?php
header('Content-type: image/jpeg');
echo file_get_contents("https://hmc1-bucket.s3.ap-south-1.amazonaws.com/new_object_key");
?>
