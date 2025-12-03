namespace GravityBikeSpline::CarEnemy
{
	/**
	 * Location uses a spring to smoothly follow the spline
	 */

	const float LocationStiffness = 50;
	const float LocationDamping = 0.6;

	/**
	 * Rotation uses SpringTo for more fluidity and overshoots
	 */
	 
	const float RotationStiffness = 10;
	const float RotationDamping = 0.3;
	const FQuat RotationOffset = FRotator(10, 0, 0).Quaternion();

	/**
	 * Visual mesh rotation based on velocity delta from previous frame
	 */

	const float MeshRotationJoltAlongSplineMultiplier = 0.2;
	const float MeshRotationHorizontalJoltSplineMultiplier = 1;
	const float MeshRotationJoltMultiplier = 0.005;
	const float MeshRotationAngleLimit = 30;
	const float MeshRotationStiffness = 10;
	const float MeshRotationDamping = 0.5;

	/**
	 * Impacts from Missiles and Throwables apply an impulse on the car
	 */
	
	const float ImpactLocationOffsetImpulse = 5000;
	const float ImpactMeshRotationImpulse = 5;

	const float HitOtherCarImpulse = 3000;

	const float DeathFromWallDotThreshold = -0.5;

	const float WallReflectAngularImpulse = -5;

	const float VeerMaxSpeed = 5000;
	const float VeerDeceleration = 500;
	const float VeerRollSpeed = 400;
	const float VeerGravity = 500;
	const float ExplodeAfterVeerDelay = 3;
	const float VeerTurnSpeed = 0.3;

	const float RespawnDelay = 1.0;
};