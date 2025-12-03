class ASanctuaryLakePerchPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent BeamRoot; 

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UStaticMeshComponent PoleMesh;

	

	UPROPERTY(EditAnywhere)
	APoleClimbActor PoleActor;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PoleActor.OnStartPoleClimb.AddUFunction(this, n"HandleClimbStarted");
		PoleActor.PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandlePerchStarted");
	}

	UFUNCTION()
	private void HandleClimbStarted(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		BeamRoot.ApplyImpulse(Player.ActorLocation, Player.ActorForwardVector * 45.0);
		ULakePerchPoleEffectEventHandler::Trigger_StartPolePerch(this);
	}

	UFUNCTION()
	private void HandlePerchStarted(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		BeamRoot.ApplyImpulse(Player.ActorLocation, Player.ActorForwardVector * 45.0);
		ULakePerchPoleEffectEventHandler::Trigger_StartPolePerch(this);
	}
};