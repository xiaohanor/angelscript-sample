/**
 * The single-player cannon.
 * Currently unused.
 */
UCLASS(Abstract)
class UDentistCannonEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ADentistCannon Cannon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistCannon>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExited() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAiming() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopAiming() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartResetting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedResetting() {}
};