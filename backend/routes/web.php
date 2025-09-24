<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PosController;


/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

// Route::get('/', function () {
//     return view('welcome');
// });

Route::get('/', [PosController::class, 'index']);

Route::get('categories', [PosController::class, 'categories'])->name('categories');
Route::get('subCategories', [PosController::class, 'subCategories'])->name('subCategories');
Route::get('items', [PosController::class, 'items'])->name('items');
