@extends('layouts.app')
@section('title', 'POS - Zafar')
@section('content')
<nav class="">
    <ul>
        <li>Zafar POS</li><!--
        --><li><a href="#">POS1</a></li><!--
        --><li><a href="#">POS2</a></li><!--
        --><li><a href="#"></a></li>
    </ul>
</nav>

<div class="row">
    {{-- 1st Col --}}
    <dir class="col-sm-3">

        {{-- Category --}}
        <div class="mb3">
            <select class="form-select form-select-lg mb-3 form-control" id="categories">
                <option selected disabled>Select Category</option>
                @foreach($cats as $row)
                    <option value="{{ $row->id }}">{{ $row->title }}</option>
                @endforeach
            </select>
        </div>

        {{-- Sub Category --}}
        <div class="mb3">
            <select class="form-select form-select-lg mb-3 form-control" id="subCategories"></select>
        </div>

        {{-- Items --}}
        <div class="mb3">
            <ul id="item" style="list-style-type: none;"></ul>
        </div>

    </dir>

    {{-- 2nd Col --}}
    <dir class="col-sm-9">
        <div class="row">
            <table class="table table-striped table-hover" name="posTable">
                {{-- <caption>POS Invoice</caption> --}}
                <thead>
                    <tr>
                        <th>Item Name</th>
                        <th>Quantity</th>
                        <th>Price</th>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody id="tblBody">
                </tbody>
                <tfoot>
                    <tr><td></td><td></td>
                        <td>Grand Total:</td><td id="gTotal"></td>
                    </tr>
                    <tr><td></td><td></td>
                        <td>Discount:<span><input type="number" value="0" onClick="updateDisc(this)" id="discPer"></span></td><td id="disc"></td>
                    </tr>
                    <tr><td></td><td></td>
                        <td>Net Payable:</td><td id="netPayable"></td>
                    </tr>
                </tfoot>
            </table>
        </div>
    </dir>
</div>

@endsection

@section('scripts')
<script type="text/javascript">
    $(document).ready(function () {
        $('#categories').on('change', function () {
            var catId = this.value;
            $('#subCategories').html('');
            $.ajax({
                url: '{{ route('subCategories') }}?category_id='+catId,
                type: 'get',
                success: function (res) {
                    $('#subCategories').html('<option value="">Select Sub-Category</option>');
                    $.each(res, function (key, value) {
                        $('#subCategories').append('<option value="' + value
                            .id + '">' + value.title + '</option>');
                    });
                    $('#item').html('<h5>Select Item</h5>');
                }
            });
        });

        $('#subCategories').on('change', function () {
            var subCatId = this.value;
            $('#item').html('');
            $.ajax({
                url: '{{ route('items') }}?subcategory_id='+subCatId,
                type: 'get',
                success: function (res) {
                    $('#item').html('<h5>Select Item</h5>');
                    $.each(res, function (key, value) {
                        $('#item').append('<li onClick=liClick(this) value="' + value
                            .id + '">' +'<span> + </span>'  +value.title + '</li>');
                    });
                }
            });
        });

    });

    var gTotal = 0;
    var disc = 0;
    var netPayable = 0;
    var rowNumber = 1;


    function liClick(e1){
        var itemName = e1.textContent;
        var itemName2 = e1.innerText;
        var qty = 1;
        var discPer = 0;
        var price = 1;
        var item_total = 0;
        var total = qty * price;
        // gTotal = parseInt(gTotal)  + parseInt(total);
        gTotal = gTotal+total;
        discPer = document.getElementById('discPer').value;
        disc = gTotal * discPer / 100;
        netPayable = gTotal - disc;
        // console.log(itemName, itemName2, qty, price, item_total, total, gTotal, netPayable, discPer); 

        $('#tblBody').append('<tr id="'+rowNumber+'" onClick=rowClick(this) class="line_items"><td>' +itemName+ '</td><td><input type="number" id="qty'+rowNumber+'" name="qty" value="'+qty +'"></td><td><input type="number" id="price'+rowNumber+'" name="price" value="'+price +'"></td><td id="item_total'+rowNumber+'">'+total +'</td></tr>');

        rowNumber++;
        
        $('#gTotal').html('');
        $('#gTotal').append(gTotal);
        $('#disc').html('');
        $('#disc').append(disc);
        $('#netPayable').html('');
        $('#netPayable').append(netPayable);


    function rowClick(e2){
        var rowClick1 = e2.id;
        var rowQtyId = 'qty'+rowClick1;
        var rowPriceId = 'price'+rowClick1;
        var rowTotalId = 'item_total'+rowClick1;

        var curQtyValue = document.getElementById(rowQtyId).value;
        var curPriceValue = document.getElementById(rowPriceId).value;

        curRowTotal = curQtyValue * curPriceValue;
        
        // getting Old gTotal & Discount
        var oldRowValue = document.getElementById(rowTotalId).innerText;
        var oldGTotal = document.getElementById("gTotal").innerText;


        // update Row Total
        document.getElementById(rowTotalId).innerText = " ";
        document.getElementById(rowTotalId).append(curRowTotal);

        // Update Invoice total, Discount and netPayable
        gTotal = oldGTotal-oldRowValue+curRowTotal
        discPer = document.getElementById('discPer').value;
        disc = gTotal * discPer / 100;
        netPayable = gTotal - disc;

        // console.log(oldRowValue, oldGTotal, gTotal, discPer);

        $('#gTotal').html('');
        $('#gTotal').append(gTotal);
        $('#disc').html('');
        $('#disc').append(disc);
        $('#netPayable').html('');
        $('#netPayable').append(netPayable);

        // console.log(rowClick1, rowQtyId, curQtyValue, curRowTotal, rowTotalId, curPriceValue);

    }

    function updateDisc(e3){
        console.log(e3.value);

        discPer = document.getElementById('discPer').value;
        disc = gTotal * discPer / 100;
        netPayable = gTotal - disc;
        $('#disc').html('');
        $('#disc').append(disc);
        $('#netPayable').html('');
        $('#netPayable').append(netPayable);
    }


    </script>
@endsection

