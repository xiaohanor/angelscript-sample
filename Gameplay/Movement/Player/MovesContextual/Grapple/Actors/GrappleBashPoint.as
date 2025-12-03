UCLASS(Abstract)
class AGrappleBashPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrappleBashPointComponent GrappleBashPoint;

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;
	UPROPERTY()
	FOnPlayerInterruptedGrapplingToPointEventSignature OnPlayerInterruptedGrapplingToPointEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleBashPoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrappleBashPoint.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrappleBashPoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrappleBashPoint.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
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

UCLASS(Abstract)
class AFloatingGrappleBashPoint : AGrappleBashPoint
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent SpringRoot;
	default SpringRoot.SpringStrength = 7.0;
	default SpringRoot.Friction = 4.5;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent Mesh;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SpringRoot.RelativeLocation.Size() < 10.0)
		{
			GrappleBashPoint.Enable(n"Moved");
			SetActorTickEnabled(false);
		}
	}

	void OnPlayerInitiatedGrappleToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent TargetedGrapplePoint) override
	{
		GrappleBashPoint.DisableForPlayer(Player.OtherPlayer, n"InUse");
	}

	void OnPlayerFinishedGrappleToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent ActivatedGrapplePoint) override
	{
		GrappleBashPoint.EnableForPlayer(Player.OtherPlayer, n"InUse");

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		SpringRoot.ApplyImpulse(Player.ActorLocation, -MoveComp.GetPendingImpulse().GetSafeNormal() * GrappleBashPoint.Settings.LaunchImpulse);

		GrappleBashPoint.Disable(n"Moved");
		SetActorTickEnabled(true);
	}
}