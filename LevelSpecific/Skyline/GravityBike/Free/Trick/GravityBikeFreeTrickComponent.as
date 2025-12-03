UCLASS(Abstract)
class UGravityBikeFreeTrickComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	
    UPROPERTY(EditDefaultsOnly, Category = "Trick")
	UHazeCameraSpringArmSettingsDataAsset TrickCamSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Back Flip")
    UCurveFloat BackFlipCurve;

	bool bIsPerformingTrick = false;
	bool bHasPerformedTrick = false;
	float TrickAlpha = 0;

	void Reset()
	{
		bIsPerformingTrick = false;
		bHasPerformedTrick = false;
		TrickAlpha = 0;
	}
}