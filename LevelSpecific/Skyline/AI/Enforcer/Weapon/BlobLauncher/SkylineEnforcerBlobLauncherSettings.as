class USkylineEnforcerBlobLauncherSettings : UHazeComposableSettings
{
		// Time before blob explodes
	UPROPERTY(Category = "Blob")
	float BlobDuration = 2.5;

	// Scale we want to reach before exploding
	UPROPERTY(Category = "Blob")
	float BlobTargetScale = 6;

	// Time before a blob division explodes
	UPROPERTY(Category = "Blob")
	float BlobDivisionDuration = 0.5;

	// How many times blobs split (relative to the very first blob)
	UPROPERTY(Category = "Blob")
	int BlobSplits = 1;

	// Into how many blobs does each blob split
	UPROPERTY(Category = "Blob")
	int BlobDivision = 6;

	// How much blobs can diverge from their optimal splitting angle
	UPROPERTY(Category = "Blob")
	float BlobDivisionAngleRandomization = 0;

	// Min range of blob divisions
	UPROPERTY(Category = "Blob")
	float BlobDivisionMinRange = 400;

	// Max range of blob divisions
	UPROPERTY(Category = "Blob")
	float BlobDivisionMaxRange = 400;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Blob")
	float BlobLaunchSpeed = 3200.0;

	// Initial impulse speed of blob division
	UPROPERTY(Category = "Blob")
	float BlobDivisionLaunchSpeed = 800.0;

	UPROPERTY(Category = "Blob")
	float BlobGravity = 982.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Blob")
	float BlobInitialCooldown = 6.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Blob")
	float BlobInterval = 4.0;

	// For how long the Gecko telegraphs before launching projectiles
	UPROPERTY(Category = "Blob")
	float BlobTelegraphDuration = 0.4;

	// For how long the Gecko does its launching projectile state
	UPROPERTY(Category = "Blob")
	float BlobAttackDuration = 0.6;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Blob")
	EGentlemanCost BlobGentlemanCost = EGentlemanCost::Large;

	// Maximum distance for using weapon
	UPROPERTY(Category = "Blob")
	float BlobAttackRange = 6500.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Blob")
	float BlobMinimumAttackRange = 300.0;

	// How much damage does the blob deal
	UPROPERTY(Category = "Blob")
	float BlobDamagePlayer = 0.3;

	// How much damage does the blob  deal
	UPROPERTY(Category = "Blob")
	float BlobDamageNpc = 150.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Blob")
	float BlobRecoveryDuration = 1.0;

	// Blob token cooldown duration
	UPROPERTY(Category = "Blob")
	float BlobAttackTokenCooldown = 3.0;
}
