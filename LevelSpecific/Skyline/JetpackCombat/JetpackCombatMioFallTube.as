class AJetpackCombatMioFallTube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Game::Zoe);
		MoveComp.AddMovementIgnoresActor(this, this);
	}
};