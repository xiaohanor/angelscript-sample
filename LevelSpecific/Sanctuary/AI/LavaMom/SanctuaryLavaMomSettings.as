namespace LavaMomTags
{
	const FName LavaMom = n"LavaMom";
	const FName Action = n"Action";
	const FName LavaMomFacePlayer = n"LavaMomFacePlayer";

	const FName AnimationBoulder = n"AnimationBoulder";
};

class USanctuaryLavaMomSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Damage")
	float CentipedeProjectileDamage = 0.15;

	// BOULDER
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderTelegraphDuration = 0.5;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderAnticipationDuration = 0.1;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderAttackDuration = 0.1;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderRecoveryDuration = 3.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderDamage = 0.2;
	
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderProjectileSpeed = 400.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderProjectileGravity = 182.0;
};

