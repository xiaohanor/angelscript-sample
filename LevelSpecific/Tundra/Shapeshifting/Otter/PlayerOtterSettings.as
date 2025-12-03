class UTundraPlayerOtterSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Tint")
	FLinearColor MorphPlayerTint = FLinearColor(0.870833, 0.0, 0.300258);

	UPROPERTY(Category = "Tint")
	FLinearColor MorphShapeTint = FLinearColor::Gray;

	/** If the otter is this distance away from the ceiling (with an upwards velocity that will hit the ceiling in question), a press on PrimaryLevelAbility will bypass player and shapeshift directly to snow monkey.
	* If the otter instead has a downwards velocity, CeilingCoyoteMaxDistance distance will be used instead (in Monkey settings) */
	UPROPERTY()
	float MaxDistanceFromCeilingToShiftToMonkey = 1000.0;
}