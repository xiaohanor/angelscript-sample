struct FTundraCrackSpringLogNyparnGrabEffectParams
{
	/* If grabbing, how long it will take for nyparn to be fully grabbed, if releasing, how long it will take for nyparn to be fully released. */
	UPROPERTY()
	float GrabDuration = 0.0;
}

struct FTundraCrackSpringLogNyparnLogEffectParams
{
	UPROPERTY()
	ATundraCrackSpringLog Log;
}

UCLASS(Abstract)
class UTundraCrackSpringLogNyparnEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ATundraCrackSpringLogNyparn Nyparn;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Nyparn = Cast<ATundraCrackSpringLogNyparn>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartGrab(FTundraCrackSpringLogNyparnGrabEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopGrab(FTundraCrackSpringLogNyparnGrabEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabLog(FTundraCrackSpringLogNyparnLogEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReleaseLog(FTundraCrackSpringLogNyparnLogEffectParams Params) {}

	/* Value between 0->1 which represents the grab alpha of nyparn. 0 is not grabbing, 1 is fully grabbed */
	UFUNCTION(BlueprintPure)
	float GetNyparnGrabAlpha() property
	{
		return Nyparn.CurrentAlpha;
	}

	/* Value between 0->1 which represents the alpha of the horizontal translation of nyparn. 0 is start position, 1 is at max translation */
	UFUNCTION(BlueprintPure)
	float GetNyparnTranslationAlpha() property
	{
		return Nyparn.CurrentTranslation / Nyparn.MaxTranslation;
	}
}