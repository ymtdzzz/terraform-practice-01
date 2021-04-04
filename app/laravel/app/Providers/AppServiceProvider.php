<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        // generate static resource url
        \Blade::directive('asset', function ($path) {
            return "<?php echo app('url')->assetFrom(config('app.asset_url'), $path); ?>";
        });
    }
}
