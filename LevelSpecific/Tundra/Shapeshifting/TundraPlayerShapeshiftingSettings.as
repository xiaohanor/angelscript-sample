class UTundraPlayerShapeshiftingSettings : UHazeComposableSettings
{
	/* If the player shapeshifted this amount of seconds ago, ignore input */
	UPROPERTY()
	float InputDelay = 0.0;

	/* If the player failed a shapeshift, how long to wait before allowing shapeshift again (TundraSetShapeshiftingShape will always happen, regardless of cooldown) */
	UPROPERTY()
	float FailDelay = 0.5;

	UPROPERTY()
	float SameShapeInputDelay = 0.3;

	/* How long it takes to morph between shapes */
	UPROPERTY()
	float MorphTime = 0.3;
}