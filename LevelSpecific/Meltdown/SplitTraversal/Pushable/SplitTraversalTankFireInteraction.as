class ASplitTraversalTankFireInteraction : AOneShotInteractionActor
{
	default Interaction.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent)
	USceneComponent MuzzleLocation;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASplitTraversalTankProjectile> Projectile;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Interaction.Disable(n"NotReady");
		OnOneShotBlendingOut.AddUFunction(this, n"OnFired");
	}

	UFUNCTION()
	private void OnFired(AHazePlayerCharacter Player, AOneShotInteractionActor InteractionComp)
	{
		SpawnActor(Projectile, MuzzleLocation.WorldLocation, MuzzleLocation.WorldRotation);
	}
};