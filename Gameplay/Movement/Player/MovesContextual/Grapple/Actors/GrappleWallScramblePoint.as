
UCLASS(Abstract)
class AGrappleWallScramblePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrappleWallScramblePointComponent GrapplePoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditDefaultsOnly)
	UPlayerWallScrambleSettings WallScrambleSettings;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	UStaticMesh MeshOverride;

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;
	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;
	UPROPERTY()
	FOnPlayerInterruptedGrapplingToPointEventSignature OnPlayerInterruptedGrapplingToPointEvent;

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
		GrapplePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrapplePoint.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrapplePoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
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