UCLASS(Abstract)
class USandSharkHazardComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve HeightAlphaCurve;

	AHazePlayerCharacter TargetPlayer;
	ASandSharkHazard Hazard;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hazard = Cast<ASandSharkHazard>(Owner);
	}
};