# Drupal-Custom

<p>Author : David N. Brett<br/>
V.1.0 - February 2020<br/>
davidnbrett@gmail.com</p>


<h2>... in progress !</h2>
<h3>Warning : scripts may not work anymore</h3>

<p>Upcoming features :</p>
<ul><li>Rewrite the deploy script to avoid errors on Ubuntu ;</li>
<li><s>Rewrite scripts and install modules/certs for an SSL only website;</s>  Done !</li>
<li><s>Implement Varnish support;</s>  Done !</li>

<h2>Dave's Drupal 8 custom build</h2>

<p>This repository contains all the elements needed to build and run my favorite website.<br/>It currently contains :</p>
<ul><li>The main composer.json with all required modules ;</li>
<li><s>A shell script that runs the first part of the initial setup automatically ;</s></li>
<li><s>An up to date copy of the Drupal database (from the development server) ;</s></li>
<li><s>The drupal configuration file containing all settings (modules conf, content types, views etc.) ;</s></li>
<li>The Apache2 virtual host file ;</li>
<li>The drupal specific varnish configuration file (vcl) ;</li></ul>    
    
<h2>Prerequisites</h2>     

<ul><li>Apache 2 webserver (see below for required modules) with SSL termination (see https://bash-prompt.net/guides/apache-varnish/) ;</li>
<li>PHP7 (PHP 7.2+ recommended, see below for required modules) ;</li>
<li>MySQL 5.7 (Percona server recommended) ;</li>
<li>Redis Server ;</li>  
<li>Varnish server (+ Hitch SSL/TLS proxy);</li>    
<li>A valid SSL certificate ;</li>
<li>Git, Composer and Drush installed on server ;</li></ul>
    
<h2>How to install</h2>    

<ol><li>Clone this repo to your local environment</li>
<li>Create the MySQL database and the user</li>     
<li>Convert the shell script to linux EOLs with : dos2unix drupal_deploy_v2.3.sh</li>
<li>Edit the deploy shell script according to your configuration (server path, database, proxy etc.)</li>
<li>Run the deploy script, get a cup of coffee</li>   
<li>Import the SQL dump file into the newly created database</li>  
<li>Import the Drupal configuration file using drush</li>
<li>Edit your settings.php : uncomment the Redis configuration</li></ol>
    

<h2>Apache2 modules required :</h2>

<ul><li>core_module</li>
<li>so_module</li>
<li>http_module</li>
<li>mpm_worker_module</li>
<li>unixd_module</li>
<li>systemd_module</li>
<li>actions_module</li>
<li>alias_module</li>
<li>auth_basic_module</li>
<li>authn_core_module</li>
<li>authn_file_module</li>
<li>authz_host_module</li>
<li>authz_groupfile_module</li>
<li>authz_core_module</li>
<li>authz_user_module</li>
<li>autoindex_module</li>
<li>cgid_module</li>
<li>dir_module</li>
<li>env_module</li>
<li>expires_module</li>
<li>include_module</li>
<li>log_config_module</li>
<li>mime_module</li>
<li>negotiation_module</li>
<li>setenvif_module</li>
<li>ssl_module</li>
<li>socache_shmcb_module</li>
<li>reqtimeout_module</li>
<li>version_module</li>
<li>proxy_module</li>
<li>proxy_http_module</li>
<li>proxy_fcgi_module</li>
<li>proxy_balancer_module</li>
<li>headers_module</li>
<li>rewrite_module</li></ul>

<h2>PHP extensions to load :</h2>

<ul><li>Core</li>
<li>date</li>
<li>libxml</li>
<li>pcre</li>
<li>filter</li>
<li>hash</li>
<li>Reflection</li>
<li>SPL</li>
<li>session</li>
<li>SimpleXML</li>
<li>standard</li>
<li>xml</li>
<li>mysqlnd</li>
<li>jsmin</li>
<li>bcmath</li>
<li>bz2</li>
<li>ctype</li>
<li>curl</li>
<li>dom</li>
<li>gd</li>
<li>gettext</li>
<li>iconv</li>
<li>imagick</li>
<li>json</li>
<li>mbstring</li>
<li>mysqli</li>
<li>newrelic</li>
<li>openssl</li>
<li>PDO</li>
<li>pdo_mysql</li>
<li>pdo_sqlite</li>
<li>zlib</li>
<li>readline</li>
<li>redis</li>
<li>sqlite3</li>
<li>tidy</li>
<li>tokenizer</li>
<li>uploadprogress</li>
<li>xmlreader</li>
<li>xmlrpc</li>
<li>xmlwriter</li>
<li>zip</li>
<li>Phar</li>
<li>Zend OPcache</li></ul>