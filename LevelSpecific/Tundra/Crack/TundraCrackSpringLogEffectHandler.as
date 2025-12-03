struct FTundraCrackSpringLogEffectParams
{
	UPROPERTY()
	ATundraCrackSpringLogNyparn Nyparn;
}

UCLASS(Abstract)
class UTundraCrackSpringLogEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ATundraCrackSpringLog SpringLog;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpringLog = Cast<ATundraCrackSpringLog>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrab(FTundraCrackSpringLogEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRelease(FTundraCrackSpringLogEffectParams Params) {}

	/* Value between 0->1 that represents how much charge the log has from being grabbed by nyparn, 0 is no tension, 1 is full tension */
	UFUNCTION(BlueprintPure)
	float GetSpringTensionAlpha() property
	{
		return -SpringLog.CurrentForce / SpringLog.MaxForce;
	}
}