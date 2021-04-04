<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Faker\Factory as Faker;
use App\Models\Book;

class BooksController extends Controller
{
    public function index()
    {
        return response()->json(Book::all());
    }

    public function store()
    {
        \Log::info('store a book');
        $book = new Book();
        $book->title = Faker::create()->name();
        $book->save();
        return response()->json($book);
    }
}
