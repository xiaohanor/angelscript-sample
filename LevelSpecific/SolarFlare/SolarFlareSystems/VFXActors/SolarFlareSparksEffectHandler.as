struct FOnSolarFlareSparksActivatedParams
{
	UPROPERTY()
	ESolarFlareSparksType Type;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;

	UPROPERTY()
	float SpriteSizeMultiplier = 1.0;

	UPROPERTY()
	float VelocityMultiplier = 1.0;
}

UCLASS(Abstract)
class USolarFlareSparksEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSparkActivate(FOnSolarFlareSparksActivatedParams Params) {}
}