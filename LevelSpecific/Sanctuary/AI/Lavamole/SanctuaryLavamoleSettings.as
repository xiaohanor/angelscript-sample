namespace LavamoleTags
{
	const FName LavaMole = n"LavaMole";
	const FName Action = n"Action";
	const FName LavaMoleFacePlayer = n"LavaMoleFacePlayer";
};

class USanctuaryLavamoleSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Damage")
	FVector DraggedOutFacingVector = -FVector::UpVector;

	UPROPERTY(Category = "Damage")
	float CentipedeProjectileDamage = 1.0;

	UPROPERTY(Category = "Dig|Down")
	float DigDownDuration = 1.0;

	UPROPERTY(Category = "Dig|Up")
	float DigUpAnticipationDuration = 1.1;

	UPROPERTY(Category = "Dig|Up")
	float DigUpDuration = 1.0;

	UPROPERTY(Category = "Whack|Squishy")
	float WhackSquishyDuration = 0.5;
	UPROPERTY(Category = "Whack|Squishy")
	float WhackDeathDuration = 5.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderTelegraphDuration = 0.5;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderAnticipationDuration = 0.1;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderAttackDuration = 0.1;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderRecoveryDuration = 3.0;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderSnowballDuration = 3.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderDamage = 0.2;
	
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderProjectileSpeed = 400.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderProjectileGravity = 182.0;

	UPROPERTY(Category = "Bite")
	float BiteForceFeedbackStrength = 0.1;

	UPROPERTY(Category = "Bite")
	float DesiredDistanceToCentoHead = 200.0;

	UPROPERTY(Category = "Bite|Scared")
	float ScaredDuration = 3.0;

	UPROPERTY(Category = "Bite|Scared")
	float ScaredWiggleRotationSpeed = 30.0;

	UPROPERTY(Category = "Bite|Pulled")
	float ScaredWiggleRotationMax = 10;

	UPROPERTY(Category = "Bite|Scared")
	float ScaredHeightInterpolationDuration = 0.1;

	UPROPERTY(Category = "Bite|Scared")
	float ScaredHeightOffset = -175.0;

	UPROPERTY(Category = "Bite|Scared")
	float ScaredBittenCountAsGrabDuration = 0.15;

	UPROPERTY(Category = "Bite|Grabbed")
	float MoleBittenBurrowSlightlyDuration = 0.1;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabAlignPlayerHeadDuration = 0.1;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabBeforeEscapeDuration = 3.0;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabOutOfBurrowDistance = 300;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabOutOfBurrowKillDistance = 400;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabbedPlayerMoveSpeed = 500;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabbedPlayerMaxSpeedSlowdown = 70;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabbedWiggleRotationMax = 15;

	UPROPERTY(Category = "Bite|Grabbed")
	float GrabbedWiggleRotationSpeed = 30.0;

	// You need to get into Tear behavior within this time, otherwise mole escapes!
	UPROPERTY(Category = "Bite|Pulled")
	float PullBeforeEscapeDuration = 15.0;

	UPROPERTY(Category = "Bite|Pulled")
	float PulledWiggleRotationMax = 25;

	UPROPERTY(Category = "Bite|Pulled")
	float PulledWiggleRotationSpeed = 8;

	UPROPERTY(Category = "Bite|Pulled")
	float PullRotateTowardsCentoForwardDuration = 0.2;

	// How stretched can mole be?
	UPROPERTY(Category = "Bite|Teared")
	float TearDistance = 1200;

	UPROPERTY(Category = "Bite|Escape")
	float EscapeSpeed = 2500;

	UPROPERTY(Category = "Bite|Escape")
	float EscapeWiggleRotationMax = 10;

	UPROPERTY(Category = "Bite|Escape")
	float EscapeWiggleRotationSpeed = 0.1;

	UPROPERTY(Category = "Bite|AlignBackToHole")
	float AlignBackToHoleDuration = 0.1;

	UPROPERTY(Category = "Bite|FallToDeath")
	float FallToDeathDuration = 0.4;

	// ----------------------
	// Mortar

	UPROPERTY(Category = "Attack|Mortar")
	int NumSpamMortarProjectiles = 10;

	UPROPERTY(Category = "Attack|Mortar")
	float MinProjectileAnticipationDuration = 0.1;
	UPROPERTY(Category = "Attack|Mortar")
	float MaxProjectileAnticipationDuration = 0.2;

	UPROPERTY(Category = "Attack|Mortar")
	float MinProjectileRecoveryDuration = 0.5;
	UPROPERTY(Category = "Attack|Mortar")
	float MaxProjectileRecoveryDuration = 0.5;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarCooldown = 0.02;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarTelegraphDuration = 0.05;
	UPROPERTY(Category = "Attack|Mortar")
	float MortarAnticipationDuration = 0.05;
	UPROPERTY(Category = "Attack|Mortar")
	float MortarAttackDuration = 1.0;
	UPROPERTY(Category = "Attack|Mortar")
	float MortarRecoveryDuration = 2.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarDamage = 0.2;
	
	UPROPERTY(Category = "Attack|Mortar")
	float MortarProjectileSpeed = 750.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarProjectileGravity = 982.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack|Mortar")
	EGentlemanCost MortarGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolLifetime = 15.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolDamagePerSecond = 0.25;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolCheckOverlapInterval = 0.1;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolDamageDistance = 500.0;
};

