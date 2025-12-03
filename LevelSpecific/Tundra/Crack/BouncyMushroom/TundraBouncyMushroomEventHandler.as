struct FTundraBouncyMushroomEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	FTundraBouncyMushroomEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

UCLASS(Abstract)
class UTundraBouncyMushroomEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BounceSmallShape(FTundraBouncyMushroomEventData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BounceHumanShape(FTundraBouncyMushroomEventData Data)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BounceBigShape(FTundraBouncyMushroomEventData Data)
	{
	}

};