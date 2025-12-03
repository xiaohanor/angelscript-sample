
UCLASS(Abstract)
class UMeltdownSoftSplitLaserWallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	ASoftSplitDoubleDoor DoubleDoorOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cast<ASoftSplitDoubleDoor> (Owner);
		DoubleDoorOwner = Cast<ASoftSplitDoubleDoor> (Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeActivate() {}
};