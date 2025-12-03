
UCLASS(Abstract)
class AGrapplePerchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UPerchPointComponent PerchPointComp;
	default PerchPointComp.bVisualizeComponent = false;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent EnterZone;
	default EnterZone.bVisualizeComponent = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent EditorIcon;
	default EditorIcon.RelativeLocation = FVector(0.0, 0.0, 65.0);

	UPROPERTY(DefaultComponent)
	UGrapplePointDrawComponent DrawComp;

	UPROPERTY(DefaultComponent)
	UPerchPointDrawComponent PerchPointDrawComp;
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
		PerchPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		PerchPointComp.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		PerchPointComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		PerchPointComp.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
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