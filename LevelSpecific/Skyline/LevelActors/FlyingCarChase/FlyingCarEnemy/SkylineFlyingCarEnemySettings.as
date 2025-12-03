namespace SkylineFlyingCarEnemy
{
	// Movement
	const float AngularImpulseFromMovement = 0.005;
	const float AngularImpulseFromMovementLimitDegrees = 30;
	const float AngularImpulseFromMovementStiffness = 10;
	const float AngularImpulseFromMovementDamping = 0.5;

	// Resolver
	const float HitOtherCarImpulse = 1200;
	const float HitOtherCarAngularImpulse = 2;

	const float DeathFromWallDotThreshold = -0.7;

	const float ReflectOffWallRestitution = 1.0;
	const float ReflectOffWallAngularImpulse = 2;
};