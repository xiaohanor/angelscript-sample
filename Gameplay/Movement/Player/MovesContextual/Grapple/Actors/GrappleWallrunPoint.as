UCLASS(Abstract)
class AGrappleWallrunPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrappleWallrunPointComponent GrappleWallrunPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGrappleWallRunPointDrawComponent DrawComp;
#endif

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;
	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;
	UPROPERTY()
	FOnPlayerInterruptedGrapplingToPointEventSignature OnPlayerInterruptedGrapplingToPointEvent;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	UStaticMesh MeshOverride;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(MeshOverride != nullptr)
			MeshComp.SetStaticMesh(MeshOverride);
		else
			MeshComp.SetStaticMesh(nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleWallrunPoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrappleWallrunPoint.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrappleWallrunPoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrappleWallrunPoint.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
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