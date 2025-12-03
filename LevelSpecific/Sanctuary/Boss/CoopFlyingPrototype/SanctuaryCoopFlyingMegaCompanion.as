class ASanctuaryCoopFlyingMegaCompanion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	EHazePlayer Player;
	AHazePlayerCharacter SelectedPlayer;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryCoopFlyingMegaCompanion OtherMegaCompanion;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SelectedPlayer = Game::GetPlayer(Player);
		AttachToActor(SelectedPlayer, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
};