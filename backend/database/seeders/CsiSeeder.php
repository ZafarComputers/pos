<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Category;
use App\Models\Subcategory;
use App\Models\Item;

class CsiSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        //
        $cat = Category::create([
        	'title' => 'Food Items',
        ]);
	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Froozen',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Chicken',
		        	'price' => 150,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Fish',
		        	'price' => 350,
		        	'qty'	=> 200,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Meat',
		        	'price' => 500,
		        	'qty'	=> 10,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Beaf',
		        	'price' => 450,
		        	'qty'	=> 20,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Fruit',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Apple',
		        	'price' => 150,
		        	'qty'	=> 20,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Mango',
		        	'price' => 100,
		        	'qty'	=> 400,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Grapes',
		        	'price' => 250,
		        	'qty'	=> 40,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Vagetable',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Onion',
		        	'price' => 10,
		        	'qty'	=> 500,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Potato',
		        	'price' => 5,
		        	'qty'	=> 400,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Lady Finger',
		        	'price' => 25,
		        	'qty'	=> 25,
		        ]);


        $cat = Category::create([
        	'title' => 'Home Accessories',
        ]);
	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Dacoration',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Indoor Plants',
		        	'price' => 15,
		        	'qty'	=> 400,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Fairy Lights',
		        	'price' => 15,
		        	'qty'	=> 40,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Wall Papers',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => '2D Wall Papers',
		        	'price' => 150,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => '3D Wall Papers',
		        	'price' => 100,
		        	'qty'	=> 30,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Kitchen Products',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Plates',
		        	'price' => 50,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Glass Fancy',
		        	'price' => 250,
		        	'qty'	=> 50,
		        ]);

        $cat = Category::create([
        	'title' => 'Beauty Products',
        ]);
	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Lip Sticks',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Matte',
		        	'price' => 75,
		        	'qty'	=> 10,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Gloss',
		        	'price' => 150,
		        	'qty'	=> 65,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Nail Paint',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Glass',
		        	'price' => 100,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Plain',
		        	'price' => 150,
		        	'qty'	=> 45,
		        ]);

        $cat = Category::create([
        	'title' => 'Electronics',
        ]);
	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Mobiles',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Samsung',
		        	'price' => 45000,
		        	'qty'	=> 4,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'IPhone Promax',
		        	'price' => 150000,
		        	'qty'	=> 10,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Computers',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Laptops',
		        	'price' => 15000,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Lenovo Think Pad',
		        	'price' => 15500,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'HP Matbook',
		        	'price' => 15900,
		        	'qty'	=> 40,
		        ]);

	        $sub = Subcategory::create([
	        	'category_id' => $cat->id,
	        	'title' => 'Air Conditionars',
	        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Kanwood',
		        	'price' => 150000,
		        	'qty'	=> 10,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Dawlance',
		        	'price' => 75000,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Pell',
		        	'price' => 150,
		        	'qty'	=> 40,
		        ]);
		        $item = Item::create([
		        	'subcategory_id' => $sub->id,
		        	'title' => 'Gree',
		        	'price' => 150,
		        	'qty'	=> 40,
		        ]);

    }
}
