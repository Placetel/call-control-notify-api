/**
 * This is a sample interceptor, the interception point are implemented in the notify handler
 *
 * So enter in placetel app your endpoint as
 * https://yourdomain/index.cfm/placetel/notify
 *
 * the request which comes from placetel looks like: /index.cfm/placetel/notify?event=CallAccepted&from=017312345678&to=022129191999&call_id=f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447
 * 
 * the notify handler itself should not be used to implement you respose
 * USE YOUR OWN INTERCEPTOR in your own application, for sample responses see below
 *
 */
component extends="coldbox.system.Interceptor"{

	property name="Notify" inject="Notify@placetel";


	function configure(){}

	function placetel_IncomingCall( event, interceptData ) {
		var prc = event.getCollection(private=true);
		var rc	= event.getCollection();

/*			
		var test =[
				{numbers=['123','1234',12345]}
				,{ringtime=5,numbers=['234','2345',2346]}
			]
		;
		prc.placetelResponse=Notify.forward(targets=test);
*/
	}

	function placetel_CallAccepted( event, interceptData ) {
		var prc = event.getCollection(private=true);
		var rc	= event.getCollection();

//		prc.placetelResponse=Notify.reject();

//		prc.placetelResponse=Notify.reject("busy");

//		prc.placetelResponse=Notify.hangup();

//		prc.placetelResponse=Notify.queue(1234);
	}

	function placetel_HungUp( event, interceptData ) {
		var prc = event.getCollection(private=true);
		var rc	= event.getCollection();


	}

}