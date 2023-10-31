package com.example.movein

import com.google.android.gms.ads.MobileAds
import android.os.Bundle
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.ConnectionResult

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {

    private lateinit var googleAPI: GoogleApiAvailability
    private var resultCode: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        //checkGooglePlayServices()
        MobileAds.initialize(this) {}
    }
//
//    private fun checkGooglePlayServices() {
//        // Native Android code for checking Google Play services compatibility
//        // You can use the GoogleApiAvailability class to perform the check.
//        // Example:
//        googleAPI = GoogleApiAvailability.getInstance()
//        resultCode = googleAPI.isGooglePlayServicesAvailable(this)
//        if (resultCode != ConnectionResult.SUCCESS) {
//            openGooglePlayServicesPage()
//        }
//    }
//
//    private fun openGooglePlayServicesPage() {
//        try {
//            val intent = googleAPI.getErrorResolutionIntent(this, resultCode)
//            intent?.let {
//                startActivityForResult(it, resultCode)
//            }
//        } catch (e: Exception) {
//            // Handle exceptions if needed.
//        }
//    }
}
