class ASkylineCraneWalkway : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent BeamRoot;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UFauxPhysicsAxisRotateComponent SidewaysRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpCallbackComp;

	UPROPERTY(DefaultComponent, Attach = SidewaysRoot)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		ImpCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleGroundLeave");
	}

	UFUNCTION()
	private void HandleGroundLeave(AHazePlayerCharacter Player)
	{
		//BeamRoot.ApplyImpulse(Player.GetActorLocation(), FVector::UpVector *- 2.5);
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		//BeamRoot.ApplyImpulse(Player.GetActorLocation(), Player.GetActorVelocity() * 1);
	}
};