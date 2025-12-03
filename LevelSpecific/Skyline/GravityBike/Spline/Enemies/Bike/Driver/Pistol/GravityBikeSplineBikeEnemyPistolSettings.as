namespace GravityBikeSpline::BikeEnemyDriver::Pistol
{
	const FName BikeEnemyDriverPistolTag = n"BikeEnemyDriverPistol";

	const float MaxTargetDistance = 20000;
	const float MaxSlowTargetDistance = 10000;
	const float AimAheadDuration = 1.0;
	const float RotateForwardDuration = 1.0;
	const float RotateToTargetDuration = 0.5;

	const float MinimumHealthToFireAccurately = 0.66;
	const float FireIfUnderSpeedAlpha = 0.4;
	const float IfUnderSpeedRecoilMultiplier = 0.5;
	const float IfUnderSpeedDamageMultiplier = 3;
};