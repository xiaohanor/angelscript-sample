namespace SandHand
{
	const FName DebugCategory = n"SandHand";
	const FName Feature = n"SandHand";

	// Aiming
	const FName TargetableCategory = n"SandHand";
	const float AutoAimRange = 3000.0;
	const float AimAfterStopFireDelay = 1;

	const float Range = 5000.0;

	// Spawning
	const float MeshScale = 4;

	// Shoot
	const float ShootDelay = 0.1;
	const float AfterShootDelay = 0.3;

	const float MaxHorizontalVelocity = 10000.0;

	const float ImpactForce = 600.0;

	// Flight
	const float Gravity = 980;

	const float HomingSpeedNear = 5;
	const float HomingNearDistance = 500;

	const float HomingSpeedFar = 0.5;
	const float HomingFarDistance = 5000;
	
	const float HomingPredictionMultiplier = 1;	// Set to <0 to disable prediction
	const float HomingMaxPredictionDistance = 500;
	
	const bool bHomeInRelativeSpace = false;
	const float HomingPredictionSmoothingDuration = 0.5;

	// UI
	const float CrosshairLifetime = 2.0;

	namespace Tags
	{
		const FName SandHand = n"SandHand";

		const FName SandHandMasterCapability = n"SandHandMasterCapability";
		const FName SandHandInputCapability = n"SandHandInputCapability";
		const FName SandHandAimCapability = n"SandHandAimCapability";
		const FName SandHandActiveCapability = n"SandHandActiveCapability";
		const FName	SandHandShootCapability = n"SandHandShootCapability";
	}
}