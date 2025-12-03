class USkylineTorHammerStolenPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	bool bStolen;
	bool bAttack;
	float AttackDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}