<?php

/**
 * Class ApiController - Your Laravel Controller
 *
 */
class ApiController {

    /**
     *
     * verify the authenticity of request
     *
     */
    public function handleCallback(Request $request) {
        $placetelSignatures = $request->header('X-PLACETEL-SIGNATURE');
        $payload = file_get_contents("php://input");
        $calculateSignatures = hash_hmac('sha256', $payload, 'your-secret');
        if (!hash_equals($placetelSignatures, $calculateSignatures)){
            dd('Could not verify request.');
        }
        //call data
        $callData = $request->all();
    }


}
