
// class USkylineFlyingCarSettings : UHazeComposableSettings
// {
// 	// Distance at which we transition from free flying to spline following
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineGrabDistance = 4500.0;

// 	// Acceleration forwards while moving along spline
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineForwardAcceleration = 155000.0;

// 	// Air drag while moving along spline
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineFriction = 6.2;

// 	// How far along the spline we steer towards
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineLookAhead = 2000.0;

// 	// How hard we turn towards the spline center when moving along it (0..1)
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineGuidanceStrength = 0.25;

// 	// At this distance from spline center, the tunnel walls will start to repulse the car
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineTunnelRepulseRadius = 1800.0;

// 	// At this distance from spline center wall repulsion is as high as side acceleration
//     UPROPERTY(Category = "SplineMovement")
// 	float SplineTunnelRepulseOuterRadius = 2500.0;

// 	// How hard we accelerate forwards when moving freely
//     UPROPERTY(Category = "FreeMovement")
// 	float FreeForwardAcceleration = 5000.0;

// 	// How hard we can accelerate up/down when moving freely
//     UPROPERTY(Category = "FreeMovement")
// 	float FreeVerticalAcceleration = 6100.0; //2200.0;

// 	// How fast we fall when moving freely
//     UPROPERTY(Category = "FreeMovement")
// 	float FreeGravity = 3200.0;

// 	// Air drag when moving freely 
//     UPROPERTY(Category = "FreeMovement")
// 	float FreeFriction = 0.6;

// 	// How fast we rotate when moving freely
//     UPROPERTY(Category = "FreeMovement")
// 	float FreeTurnSpeed = 3.0;

// 	// How long the boost will last
//     UPROPERTY(Category = "Boost")
// 	float SplineSpeedBoostDuration = 0.6;

// 	// How much car will travel via boost
// 	UPROPERTY(Category = "Boost")
// 	float BoostImpulse = 3000.0;
// }

// asset SkylineFlyingCarOldMovementSheet of UHazeCapabilitySheet
// {
// 	SkylineFlyingCarOldMovementSheet.AddCapability(n"FlyingCarSplineMovementCapability");
// 	SkylineFlyingCarOldMovementSheet.AddCapability(n"FlyingCarTurnCapability");
// 	SkylineFlyingCarOldMovementSheet.AddCapability(n"FlyingCarBoostCapability");	
// 	SkylineFlyingCarOldMovementSheet.AddCapability(n"FlyingCarFreeMovementCapability");
// 	SkylineFlyingCarOldMovementSheet.AddCapability(n"FlyingCarSplineFinderCapability");
// }
