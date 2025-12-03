class UEnforcerHoveringSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "ScenepointReposition")
	float ScenepointRepositionMoveSpeed = 2000;

	UPROPERTY(Category = "ScenepointReposition")
	float ScenepointRepositionStuckDuration = 1.0;

	UPROPERTY(Category = "ScenepointReposition")
	float ScenepointRepositionInterval = 5.0;


 	UPROPERTY(Category = "Chase")
	float HoverChaseMinRange = 1000;

	UPROPERTY(Category = "Chase")
	float HoverChaseMoveSpeed = 2000;

	UPROPERTY(Category = "Chase")
	float HoverChaseHeight = 600;


	UPROPERTY(Category = "Drift")
	float HoverDriftMoveSpeed = 200;

	UPROPERTY(Category = "Drift")
	float HoverDriftCooldownMin = 0.5;

	UPROPERTY(Category = "Drift")
	float HoverDriftCooldownMax = 2;

	UPROPERTY(Category = "Drift")
	float HoverDriftHeight = 400;


	UPROPERTY(Category = "Drift")
	float HoverAvoidWallsDistance = 1000;

	UPROPERTY(Category = "Drift")
	float HoverAvoidWallsMoveSpeed = 500;

	UPROPERTY(Category = "Drift")
	float HoverAvoidWallsDuration = 1.0;


	UPROPERTY(Category = "HoverAtScenepoint")
	float HoverAtScenepointMoveSpeed = 500;

	UPROPERTY(Category = "HoverAtScenepoint")
	float HoverAtScenepointCooldown = 1.0;


	UPROPERTY(Category = "Bobbing")
	float BobbingAmplitude = 50;

	UPROPERTY(Category = "Bobbing")
	float BobbingMinInterval = 1.5;

	UPROPERTY(Category = "Bobbing")
	float BobbingMaxInterval = 2.5;


	UPROPERTY(Category = "Thrown")
	float HoverThrownMaxImpulse = 1500.0;

	UPROPERTY(Category = "Billboard")
	FVector BillboardDetectionSizePadding = FVector(100.0, 100.0, 80.0);

	UPROPERTY(Category = "Death")
	float BillboardDeathDuration = 3.0;

	UPROPERTY(Category = "Death")
	float BillboardDeathStumbleAwayBeforeExplosionDistance = 0.0; // If 0.0, we won't stumble

	UPROPERTY(Category = "Death")
	float BillboardDeathStumbleAwayBeforeExplosionDuration = 0.3;

	UPROPERTY(Category = "Death")
	float BillboardDeathStumbleAwayBeforeExplosionDelay = 0.0;

	UPROPERTY(Category = "Death")
	float BillBoardDeathFallSpeed = 2000.0;

	
	UPROPERTY(Category = "BillboardImpact")
	float BillboardThrownImpactForce = 400.0;

	UPROPERTY(Category = "Death")
	float BillboardZoneExplosionForce = 1000.0;

	// Settings for force of exploding sticky bomb is in SkylineEnforcerStickyBombLauncherSettings.as

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

	// Initial impulse speed of blob division
	UPROPERTY(Category = "Blob")
	float BlobDivisionLaunchSpeed = 800.0;

	UPROPERTY(Category = "Blob")
	float BlobGravity = 982.0 * 2.0;

	// How much damage does the blob deal
	UPROPERTY(Category = "Blob")
	float BlobDamagePlayer = 0.6;
}
