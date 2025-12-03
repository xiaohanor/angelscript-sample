
UCLASS(Abstract)
class AGrappleLaunchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrappleLaunchPointComponent GrappleLaunchPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGrappleLaunchPointDrawComponent DrawComp;
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
		GrappleLaunchPoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrappleLaunchPoint.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrappleLaunchPoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrappleLaunchPoint.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
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