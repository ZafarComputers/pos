<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Pos;
use App\Models\Category;
use App\Models\Subcategory;
use App\Models\Item;

class PosController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        // Get All Categories
        $cats = Category::all();
        $cat1 = $cats->first();

        return view('pos', compact('cats'));
    }


    public function categories()
    {
        //
        $catagories = DB::table('catagories')
            ->get();
        
        return $catagories;
    }

    public function subCategories(Request $request)
    {
        $subcategories = DB::table('subcategories')
            ->where('category_id', $request->category_id)
            ->get();
        
        if (count($subcategories) > 0) {
            return response()->json($subcategories);
        }
    }

    public function items(Request $request)
    {
        $items = DB::table('items')
            ->where('subcategory_id', $request->subcategory_id)
            ->get();
        
        if (count($items) > 0) {
            return response()->json($items);
        }
    }



}
