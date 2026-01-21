<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;

class TestController extends Controller
{
    public function call()
    {
        $res = Http::timeout(2)->get('http://io-service:8080/io');

        return response()->json([
            'result' => $res->body()
        ]);
    }
}
