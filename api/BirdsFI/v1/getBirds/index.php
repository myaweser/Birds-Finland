<?php
$appVersion =  $_GET['appVersion'];

if($appVersion == "1.0.0") {
    header("location: json/05-01-2017.json");
    exit();
} else if($appVersion == "1.0.1") {
    header("location: json/11-01-2017.json");
    exit();
} else if($appVersion == "1.0.2") {
    header("location: json/11-01-2017.json");
    exit();
} else if($appVersion == "1.0.3") {
    header("location: json/11-01-2017.json");
    exit();
} else if($appVersion == "1.0.4") {
    header("location: json/11-01-2017.json");
    exit();
} else if($appVersion == "1.0.5") {
    header("location: json/11-01-2017.json");
    exit();
} else if($appVersion == "1.1") {
    header("location: json/11-01-2017.json");
    exit();
} else {
    header("location: json/unknownVersion.json");
    exit();
}
?>