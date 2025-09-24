<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Models\Category;
use App\Models\Item;

class Subcategory extends Model
{
    use HasFactory;
    use SoftDeletes;
    protected $dates = ['deleted_at'];
    protected $guarded = [];

    function items(){
        return $this->hasMany(Item::class);
    }

    function category(){
        return $this->hasOne(Category::class);
    }

}
