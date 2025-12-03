
namespace AdultDragonAcidBeam
{
	// Amount reduced per second while firing the beam
	const float AcidReductionAmount = 0.3;
	// Amount recharged per second when no longer firing
	const float AcidRechargeSpeed = 1.75;
	// Acceleration speed to reach full recharge speed
	const float AcidAccelerationRechargeSpeed = 2.0;

	// Anticipation delay before the beam initially comes out
	const float BeamAnticipationDelay = 0.1;
	// Minimum duration for the beam to be active
	const float BeamMinimumDuration = 0.5;
	// Recharge duration that we are not allowed to chain beams during
	const float BeamRechargeCooldown = 0.2;
	// Maximum length of the beam if it doesn't hit anything
	const float BeamLength = 15000.0;
	// Minimum acid charge needed to fire the beam
	const float BeamMinimumAcidCharge = 1.0;

	// How often to place puddles of acid with the beam
	const float PuddlePlacementInterval = 0.1;
	// Radius of puddle placed by spray projectile
	const float PuddleRadius = 800.0;
	// Duration of puddle placed by spray projectile
	const float PuddleDuration = 3.0;

	// How often acid hits are generated when something is hit by the beam
	const float AcidHitInterval = 0.025;

	// Socket name on the dragon that acid should spray from
	const FName ShootSocket = n"Jaw";
	// Offset from the socket on the dragon that acid should spray from
	const FVector ShootSocketOffset(50.0, 0.0, 0.0);
};