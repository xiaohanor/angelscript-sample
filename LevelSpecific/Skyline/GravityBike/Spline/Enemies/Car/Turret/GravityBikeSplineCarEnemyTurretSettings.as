namespace GravityBikeSpline::CarEnemy::Turret
{
	const FName CarEnemyTurretTag = n"CarEnemyTurret";
	const FName CarEnemyTurretFireTag = n"CarEnemyTurretFire";

	const float MaxTargetDistance = 20000;
	const float MaxSlowTargetDistance = 10000;
	const float AimAheadDuration = 1.0;
	const float RotateForwardDuration = 1.0;
	const float RotateToTargetDuration = 0.5;

	const float MinimumHealthToFireAccurately = 0.66;
	const float FireIfUnderSpeedAlpha = 0.4;
	const float IfUnderSpeedRecoilMultiplier = 0.5;
	const float IfUnderSpeedDamageMultiplier = 3;

	const float MaxPitch = 45.0;
	const float MinPitch = -25.0;
};