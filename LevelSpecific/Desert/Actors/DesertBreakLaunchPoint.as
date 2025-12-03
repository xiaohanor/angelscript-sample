UCLASS(Abstract)
class ADesertBreakLaunchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UGrappleLaunchPointComponent LaunchPointComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	ADesertBreakLaunchPoint DisableForOtherPlayerPoint; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchPointComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"FinishedGrapplingToPoint");
	}

	UFUNCTION()
	private void FinishedGrapplingToPoint(AHazePlayerCharacter Player,
	                                      UGrapplePointBaseComponent GrapplePoint)
	{
		//Temporarily disabled to prevent blocker.
		
		//BreakLaunch(Player);
		// LaunchPointComp.DisableForPlayer(Player, this);
		// LaunchPointComp.DestroyComponent(this);
	}

	UFUNCTION(BlueprintEvent)
	void BreakLaunch(AHazePlayerCharacter Player)
	{
		//BP stuff :)
	}
};