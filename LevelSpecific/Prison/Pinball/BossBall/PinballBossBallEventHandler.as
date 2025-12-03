UCLASS(Abstract)
class UPinballBossBallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballBossBall BossBall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched(FPinballOnLaunchedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagnetDroneAttractKnockback(FOnMagnetDroneAttachedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKnockedOut() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamaged() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath() {}

	UFUNCTION(BlueprintPure)
	USceneComponent GetAttachComponent() const
	{
		return BossBall.RootComponent;
	}
};