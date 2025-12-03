struct FOnMoonGuardianCatRoarParams
{
	UPROPERTY()
	USceneComponent AttachComponent;

	FOnMoonGuardianCatRoarParams(USceneComponent Attach)
	{
		AttachComponent = Attach;
	}
}

UCLASS(Abstract)
class UMoonGuardianCatEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatRoarStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatRoar(FOnMoonGuardianCatRoarParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatHalfAsleep() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatFullAsleep() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatWakeUp() {}
};