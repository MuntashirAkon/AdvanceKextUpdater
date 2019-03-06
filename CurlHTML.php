<?php
/**
 * Created by PhpStorm.
 * User: muntashir
 * Date: 5/15/18
 * Time: 7:01 PM
 */

require_once __DIR__ . '/CurlHTMLException.php';

class CurlHTML{
    const USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3595.2 Safari/537.36';
    private $curl;
    private $host;
    private $cookie_file;
    /**
     * CurlHTML constructor.
     * @param string     $url            The desired link
     * @param array|null $headers        Additional headers other than 'User-Agent'
     * @param array      $extra_curl_opt Additional cURL options
     * @throws CurlHTMLException
     */
    public function __construct($url, $headers = null, $extra_curl_opt = []){
        if(!self::up_and_running($url)) throw new CurlHTMLException('Could not resolve host: ' . parse_url($url, PHP_URL_HOST), 6);
        $url = $this->properURL($url);
        $this->host = parse_url($url, PHP_URL_HOST);
        $this->cookie_file = '/tmp/' . $this->host;
        touch($this->cookie_file);
        $this->curl = curl_init($url);
        curl_setopt($this->curl, CURLOPT_USERAGENT, self::USER_AGENT);
        curl_setopt($this->curl, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($this->curl, CURLOPT_AUTOREFERER, true);
        curl_setopt($this->curl, CURLOPT_CONNECTTIMEOUT, 5000);
        // Use cookies
        curl_setopt($this->curl, CURLOPT_COOKIEJAR, $this->cookie_file);
        curl_setopt($this->curl, CURLOPT_COOKIEFILE, $this->cookie_file);
        // Set headers if necessary
        if(is_array($headers)) curl_setopt($this->curl, CURLOPT_HTTPHEADER, $headers);
        // Set extra curl options if necessary
        foreach($extra_curl_opt as $option => $value){
            curl_setopt($this->curl, $option, $value);
        }
    }

    /**
     * @return array
     * @throws CurlHTMLException
     */
    public function get_json(){
        return json_decode($this->get_html(), true);
    }
    /**
     * @return string
     * @throws CurlHTMLException
     */
    public function get_html(){
        return $this->get_binary();
    }

    /**
     * @return string
     * @throws CurlHTMLException
     */
    public function get_binary(){
        curl_setopt($this->curl, CURLOPT_RETURNTRANSFER, 1);
        $res = curl_exec($this->curl);
        if(curl_errno($this->curl)){
            throw new CurlHTMLException(curl_error($this->curl), curl_errno($this->curl));
        }
        return $res;
    }

    /**
     * @param string $filename
     * @param bool   $resume
     * @return bool
     * @throws CurlHTMLException
     */
    public function save_binary($filename, $resume = false){
        // Create or append to the file
        $handler = fopen($filename, $resume ? 'ab' : 'wb');
        if($handler == false) throw new CurlHTMLException('File cannot be opened for downloading!', 324);
        curl_setopt($this->curl, CURLOPT_FILE, $handler);
        // If resuming is requested, resume download
        if(file_exists($filename)) {
            curl_setopt($this->curl, CURLOPT_RESUME_FROM, filesize($filename));
        }
        // Execute curl
        $res = curl_exec($this->curl);
        if(curl_errno($this->curl)){
            throw new CurlHTMLException(curl_error($this->curl), curl_errno($this->curl));
        }
        // Check if the result was a success: important for saving
        $response_code = curl_getinfo($this->curl, CURLINFO_RESPONSE_CODE);
        if($response_code != 200) {
            // It's crucial to delete the
            throw new CurlHTMLException('Failed to download file properly, invalid response', $response_code);
        }
        fclose($handler);
        return $res; // = true
    }

    /**
     * Is the following host is up and running
     * @param string $link
     * @return bool
     */
    public static function up_and_running($link){
        $host = parse_url($link, PHP_URL_HOST);
        if($socket =@ fsockopen($host, 80, $err_no, $err_str, 30)) {
            fclose($socket);
            return true;
        } else {
            return false;
        }
    }

    private function properURL($url) {
        $path = parse_url($url, PHP_URL_PATH);
        if (strpos($path,'%') !== false) return $url; //avoid double encoding
        else {
            $encoded_path = array_map('rawurlencode', explode('/', $path));
            return str_replace($path, implode('/', $encoded_path), $url);
        }
    }

    public function __destruct(){ curl_close($this->curl); }
}
