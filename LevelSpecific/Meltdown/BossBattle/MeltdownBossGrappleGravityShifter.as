class AMeltdownBossGrappleGravityShifter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGrappleLaunchPointComponent Grapple;

	UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Override;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Grapple.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"GrappleShift");
	}

	 
	UFUNCTION()
	private void GrappleShift(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		Player.ClearGravityDirectionOverride(n"GrappleShift");
		Player.OverrideGravityDirection(-ActorUpVector,n"GrappleShift", Priority);
	}

	
};