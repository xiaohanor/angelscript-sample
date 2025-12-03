class UMoonMarketPlayerRideMothComponent : UActorComponent
{
	AMoonMarketMoth Moth;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
};