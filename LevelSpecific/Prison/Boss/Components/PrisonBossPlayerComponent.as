class UPrisonBossPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	APrisonBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Boss = TListedActors<APrisonBoss>().GetSingle();
	}
}