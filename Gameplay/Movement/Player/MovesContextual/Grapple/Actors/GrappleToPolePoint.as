
UCLASS(Abstract)
class AGrappleToPolePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrappleToPolePointComponent GrappleToPolePoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGrapplePointDrawComponent DrawComp;
#endif

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;
	UPROPERTY()
	FOnPlayerInterruptedGrapplingToPointEventSignature OnPlayerInterruptedGrapplingToPointEvent;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	APoleClimbActor PoleActor;

	UPROPERTY(EditInstanceOnly, Category = "Settings", Meta = (ClampMin = "0.0"))
	float GrapplePointHeight = 0;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	UStaticMesh MeshOverride;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(MeshOverride != nullptr)
			MeshComp.SetStaticMesh(MeshOverride);

		if(PoleActor != nullptr)
			SetupOnLinkedPoleActor();
	}

	void SetupOnLinkedPoleActor()
	{
		GrappleToPolePoint.SetPoleReference(PoleActor);

		if(GrapplePointHeight > PoleActor.Height)
			GrapplePointHeight = PoleActor.Height;

		FVector NewPointLocation = (PoleActor.ActorLocation + (PoleActor.ActorUpVector * GrapplePointHeight)) - ((PoleActor.ActorLocation - ActorLocation).ConstrainToPlane(PoleActor.ActorUpVector).GetSafeNormal() * PoleActor.EnterZone.Shape.CapsuleRadius) ;
		FRotator NewRotation = FRotator::MakeFromXZ((PoleActor.ActorLocation - ActorLocation).ConstrainToPlane(PoleActor.ActorUpVector).GetSafeNormal(), PoleActor.ActorUpVector);
		SetActorLocationAndRotation(NewPointLocation, NewRotation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleToPolePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrappleToPolePoint.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrappleToPolePoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrappleToPolePoint.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
	}

	UFUNCTION()
	void OnPlayerInitiatedGrappleToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		OnPlayerInitiatedGrappleToPointEvent.Broadcast(Player, TargetedGrapplePoint);
	}

	UFUNCTION()
	private void OnGrappleHookReachedGrapplePoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent ReachedGrapplePoint)
	{
		OnGrappleHookReachedGrapplePointEvent.Broadcast(Player, ReachedGrapplePoint);
	}

	UFUNCTION()
	void OnPlayerFinishedGrappleToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent ActivatedGrapplePoint)
	{
		OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, ActivatedGrapplePoint);
	}

	UFUNCTION()
	private void OnPlayerInterruptedGrapplingToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent InterruptedGrapplePoint)
	{
		OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, InterruptedGrapplePoint);
	}
}