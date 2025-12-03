struct FSummitFlyingBirdFlockParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	AHazePlayerCharacter ClosestPlayer = nullptr;

	FSummitFlyingBirdFlockParams(FVector NewLoc, AHazePlayerCharacter InPlayer)
	{
		Location = NewLoc;
		ClosestPlayer = InPlayer;
	}

	FSummitFlyingBirdFlockParams(FVector NewLoc)
	{
		Location = NewLoc;
	}
}

UCLASS(Abstract)
class USummitFlyingBirdFlockEventHandler : UHazeEffectEventHandler
{
	ASummitFlyingBirdFlockPosition Birds;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Birds = Cast<ASummitFlyingBirdFlockPosition>(Owner);
	}

	UFUNCTION(BlueprintPure)
	FVector GetFlockCenter() const
	{
		return Birds.BirdMiddleLoc.Value;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartScatter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopScatter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateLocation(FSummitFlyingBirdFlockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartDefaultReveal() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartWatertempleInnerStoneBeastReveal() {}
};