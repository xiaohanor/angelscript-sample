struct FGravityBikeSplineEnemyMissileSettings
{
	UPROPERTY()
	float FlyStraightMoveSpeed = 4000;
	UPROPERTY()
	float FlyStraightTime = 1.0;

	UPROPERTY()
	float TurnAroundMoveSpeed = 4000;
	UPROPERTY()
	float TurnAroundTurnSpeed = 5;

	UPROPERTY()
	float HomingMoveSpeed = 4000;
	UPROPERTY()
	float HomingTurnSpeed = 20;

	UPROPERTY()
	float DroppedMoveSpeed = 15000;
	UPROPERTY()
	float DroppedTurnSpeed = 100;

	UPROPERTY()
	float HazeSphereOpacity = 0.075;

	UPROPERTY()
	float PlayerDamage = 0.4;

	const float EnemyDamage = 0.75;
	const bool bEnemyDamageIsFraction = false;
};

namespace GravityBikeSpline::EnemyMissile
{
	const FName EnemyMissileTag = n"EnemyMissile";
};