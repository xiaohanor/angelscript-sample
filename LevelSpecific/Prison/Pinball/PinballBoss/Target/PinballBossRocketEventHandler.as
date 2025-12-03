UCLASS(Abstract)
class UPinballBossRocketEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballBossRocket Rocket;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rocket = Cast<APinballBossRocket>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReleased() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReset() {}
};