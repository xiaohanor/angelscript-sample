struct FTundraSwingEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	UTundraPlayerShapeshiftingComponent ShapeComp;
}

UCLASS(Abstract)
class UTundraSeesawSwingEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded(FTundraSwingEventData PlayerData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched(FTundraSwingEventData PlayerData) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBothPlayersEntered() {}
};