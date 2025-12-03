class ASanctuaryLakeWooblePerchSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent BeamRoot;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UStaticMeshComponent PoleMesh;

	UPROPERTY(EditAnywhere)
	APerchSpline PerchSpline;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchSpline.OnPlayerJumpedOnSpline.AddUFunction(this, n"HandlePerchJumpedStarted");
		PerchSpline.OnPlayerLandedOnSpline.AddUFunction(this, n"HandleOnLandedSpline");
	}


	UFUNCTION()
	private void HandlePerchJumpedStarted(AHazePlayerCharacter Player)
	{
		BeamRoot.ApplyImpulse(Player.ActorLocation, Player.ActorForwardVector * 45.0);
		ULakePerchPoleEffectEventHandler::Trigger_StartPolePerch(this);
	}

	UFUNCTION()
	private void HandleOnLandedSpline(AHazePlayerCharacter Player)
	{
		BeamRoot.ApplyImpulse(Player.ActorLocation, Player.ActorForwardVector * 45.0);
		ULakePerchPoleEffectEventHandler::Trigger_StartPolePerch(this);
	}

	
};