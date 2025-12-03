event void FSplitSlidePlayerGrappledToHoverboardSignature();

class AMeltdownSplitSlideFakeHoverBoard : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent HoverBoardRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent BroomRoot;

	UPROPERTY(EditInstanceOnly)
	APerchPointActor GrappleActor;

	UPROPERTY()
	FSplitSlidePlayerGrappledToHoverboardSignature OnPlayerGrappledToHoverboard;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		GrappleActor.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandleStartedPerching");
		//GrappleActor.PerchPointComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"HandleFinishedGrappling");	
	}

	UFUNCTION()
	private void HandleStartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		OnPlayerGrappledToHoverboard.Broadcast();
		GrappleActor.AddActorDisable(this);
		AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleFinishedGrappling(AHazePlayerCharacter Player,
	                                     UGrapplePointBaseComponent ActivatedGrapplePoint)
	{
		OnPlayerGrappledToHoverboard.Broadcast();
		GrappleActor.AddActorDisable(this);
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DroneRelativeLocation = FVector::UpVector * Math::Sin(Time::GameTimeSeconds * 0.75) * 20.0;
		FRotator DroneRelativeRotation = FRotator(0.0, Math::Sin(Time::GameTimeSeconds * 0.5) * 10.0, 0.0);
		
		HoverBoardRoot.SetRelativeLocationAndRotation(DroneRelativeLocation, DroneRelativeRotation);
		BroomRoot.SetRelativeLocationAndRotation(DroneRelativeLocation, DroneRelativeRotation);
	}
};