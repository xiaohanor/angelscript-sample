namespace Pirate
{
	namespace Ship
	{
		const float SpringStiffness = 10;
		const float SpringDamping = 0.3;

		const float MoveSpeed = 1000;
		const float Acceleration = 200;
		const float TurnSpeed = 4.0;

		const bool bDepenetrate = true;
		const float ImpulseNeededForImpact = 300;
		const float ImpulseNeededForMaxImpact = 600;
		const float ImpactResetTime = 2;
		const float ImpactMinImpulse = 0.2;
		const float ImpactMaxImpulse = 0.3;

		const float FrontSplashResetTime = 2;
		const float FrontSplashThreshold = 0.2;
		const float FrontSplashMinimumSpeed = 300;

		const float MastRotateDuration = 5;
		const float MaxMastRotateAmount = 30;

		const bool bDrawAiming = true;
		const bool bDrawRedCircleOnAimHit = true;

		const int SinkMaxDamages = 6;
		const float SinkDeceleration = 0.5;
		const float SinkFallAcceleration = 50;
		const float SinkFallSpeed = -100;
		const FRotator SinkTargetRotation = FRotator(-30, 0, 40);
		const float SinkRotateSpeed = 0.03;
		const float SinkDepthThreshold = -2500;
	}

	namespace Helm
	{
		const bool bUseStickSpin = true;
		const float TurnAcceleration = 2;
		const float TurnSpeed = 1;
		const float MaxTurnAngle = 120;

		const float StickSpinTurnSpeed = 1;
		const float StickSpinMaxTurnAngle = 120;
	}

	namespace Cannon
	{
		const float YawAcceleration = 10;
		const float YawSpeed = 40;

		const float PitchAcceleration = 10;
		const float PitchSpeed = 30;

		const float ReloadTime = 1.5;
	}

	namespace CannonBall
	{
		const float LaunchSpeed = 3000;
		const float Gravity = 600;
		const float InheritVelocityScale = 3;
	}

	namespace Telescope
	{
		const bool bAlwaysFocusOnTarget = true;
		const float BlendInTime = 1;
		const float BlendOutTime = 1;
		const float RegularFOV = 50;
		const float ZoomFOV = 30;
	}

	namespace EnemySloop
	{
		const float SpawnUnderwaterOffset = 2500;

		const float SpringStiffness = 20;
		const float SpringDamping = 0.6;
		const float EnemyPatrolSpeed = 300;
		const float DirectHitImpulse = 2000;

		const float MastRotateDuration = 5;
		const float MaxMastRotateAmount = 60;

		const int HitsNeededToSink = 4;
		const float SinkExplodeDuration = 1;

		const float SinkDeceleration = 0.5;
		const float SinkFallAcceleration = 100;
		const float SinkFallSpeed = -300;
		const FRotator SinkTargetRotation = FRotator(-40, 0, 60);
		const float SinkRotateSpeed = 0.2;
		const float SinkDepthThreshold = -2500;
	}

	namespace Player
	{
		const bool bOnlySpawnSharkIfFarFromShip = true;
		const float SharkSpawnDistanceFromShip = 3000;
		
		const float SharkSpawnDelay = 6;
		const float SharkMoveSpeed = 100;
	}

	namespace Weather
	{
		const float MinWaveAmplitude = 0.8;
		const float MaxWaveAmplitude = 8;

		const float StartStormDuration = 10;
		const float StopStormDuration = 20;
	}

	namespace Flag
	{
		const bool bAllowReturningFlags = false;
	}
}