
namespace TeenDragonTailAttack
{
	// Set to true to draw hitboxes to screen while tracing
	const bool bDebugHitboxes = false;

	const float FirstAttackDuration = 0.9;
	const float FirstAttackSettleTime = 0.1;
	const float FirstAttackComboWindow = 0.5;
	const float FirstAttackForwardMovementDistance = 0.0;
	const float FirstAttackDamage = 0.5;

	const FName FirstAttackHitboxBone = n"LeftHand";
	const FTransform FirstAttackHitboxTransform(FQuat::Identity, FVector(0.0, 0.0, 200.0), FVector(100.0, 100.0, 100.0));
	const float FirstAttackHitboxStartTime = 0.5;
	const float FirstAttackHitboxEndTime = 0.7;

	const float SecondAttackDuration = 0.9;
	const float SecondAttackSettleTime = 0.1;
	const float SecondAttackComboWindow = 0.5;
	const float SecondAttackForwardMovementDistance = 0.0;
	const float SecondAttackDamage = 0.5;

	const FName SecondAttackHitboxBone = n"LeftHand";
	const FTransform SecondAttackHitboxTransform(FQuat::Identity, FVector(0.0, 0.0, 200.0), FVector(100.0, 100.0, 100.0));
	const float SecondAttackHitboxStartTime = 0.5;
	const float SecondAttackHitboxEndTime = 0.7;

	const float ThirdAttackDuration = 0.9;
	const float ThirdAttackForwardMovementDistance = 632.0;
	const float ThirdAttackDamage = 0.5;

	const FName ThirdAttackHitboxBone = n"LeftHand";
	const FTransform ThirdAttackHitboxTransform(FQuat::Identity, FVector(0.0, 0.0, 200.0), FVector(100.0, 100.0, 100.0));
	const float ThirdAttackHitboxStartTime = 0.5;
	const float ThirdAttackHitboxEndTime = 0.7;
};

namespace TeenDragonGroundPoundAttack
{
	// Delay before starting the dive movement
	const float DiveDelay = 0.1;
	// Initial speed to dive at after pressing the button
	const float DiveInitialSpeed = 2000.0;
	// Maximum speed to reach while diving down with the ground pound
	const float DiveMaxSpeed = 4000.0;
	// Acceleration to dive down with the ground pound
	const float DiveAcceleration = 4000.0;

	// Radius to hit around the land location
	const float AttackRadius = 500.0;
	// Duration of the attack after landing
	const float AttackDuration = 0.5;
	// Damage dealt to enemies hit by the ground pound attack
	const float AttackDamage = 50.0;
};