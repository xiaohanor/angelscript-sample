struct FMoonMarketPolymorphEventParams
{
	UPROPERTY()
	FString MorphTag;

	UPROPERTY()
	AHazePlayerCharacter Player;

	FMoonMarketPolymorphEventParams(FString InTag, AActor Owner)
	{
		MorphTag = InTag;
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}

UCLASS(Abstract)
class UMoonMarketPolymorphedOwnerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMorph(FMoonMarketPolymorphEventParams Params) 
	{
		Print("Shapeshift into " + Params.MorphTag);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnmorph(FMoonMarketPolymorphEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounceOrJump(FMoonMarketPolymorphEventParams Params) {}
};