
UCLASS(Abstract)
class AGrappleLaunchPointSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UGrappleLaunchPointComponent GrapplePointZoe;
	default GrapplePointZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default GrapplePointZoe.bVisualizeComponent = false;

	UPROPERTY(DefaultComponent, NotEditable)
	UGrappleLaunchPointComponent GrapplePointMio;
	default GrapplePointMio.UsableByPlayers = EHazeSelectPlayer::Mio;
	default GrapplePointMio.bVisualizeComponent = false;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent EditorIcon;

	UPROPERTY(DefaultComponent)
	UGrapplePointDrawComponent DrawComp;
#endif

	UPROPERTY(EditAnywhere, Meta = (ShowOnlyInnerProperties))
	FGrappleLaunchPointTargetableSettings GrappleSettings;

	UPROPERTY(EditAnywhere, Category = "Grapple Settings", Meta = (EditCondition = "false", EditConditionHides))
	bool bConvertedSettings = false;

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;
	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;
	UPROPERTY()
	FOnPlayerInterruptedGrapplingToPointEventSignature OnPlayerInterruptedGrapplingToPointEvent;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PrePhysics;
	default PrimaryActorTick.EndTickGroup = ETickingGroup::TG_PrePhysics;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrapplePointMio.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrapplePointMio.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrapplePointMio.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrapplePointMio.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");

		GrapplePointZoe.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrapplePointZoe.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		GrapplePointZoe.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
		GrapplePointZoe.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (!bConvertedSettings)
			GrappleSettings.GatherFromTargetable(GrapplePointMio);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (!bConvertedSettings)
		{
			GrappleSettings.GatherFromTargetable(GrapplePointMio);
			bConvertedSettings = true;
		}

		GrappleSettings.ApplyToTargetable(GrapplePointMio);
		GrappleSettings.ApplyToTargetable(GrapplePointZoe);
	}
#endif

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

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MovePoints(DeltaSeconds, false);
	}

	void MovePoints(float DeltaTime, bool bSnap)
	{
		for (auto Player : Game::GetPlayers())
		{
			UGrappleLaunchPointComponent Point;
			if(Player.IsZoe())
				Point = GrapplePointZoe;
			else
				Point = GrapplePointMio;

			if (Point.bIsPlayerGrapplingToPoint[Player])
				continue;

			// Take the player's view rotation into account for finding which point to grapple to
			FVector ViewForward = Player.ViewRotation.ForwardVector;
			ViewForward = ViewForward.ConstrainToPlane(Player.MovementWorldUp);

			float VisibleRange = Point.ActivationRange + Point.AdditionalVisibleRange;

			FVector LineStart = Player.ActorLocation;
			FVector LineEnd = LineStart + ViewForward * VisibleRange;

			FSplinePosition SplinePos = Spline.GetClosestSplinePositionToLineSegment(LineStart, LineEnd);

			FVector WidgetLocation = Point.WorldTransform.TransformPosition(Point.WidgetVisualOffset);

			if (bSnap)
			{
				WidgetLocation = Point.WorldLocation;
			}
			else
			{
				WidgetLocation = Math::VInterpTo(
					WidgetLocation,
					SplinePos.WorldLocation,
					DeltaTime,
					4.0
				);
			}

			Point.WorldLocation = SplinePos.WorldLocation;
			Point.WidgetVisualOffset = Point.WorldTransform.InverseTransformPosition(WidgetLocation);

			//Debug::DrawDebugSphere(SplinePos.WorldLocation, 10.0, LineColor = GetColorForPlayer(Player.Player));
		}
	}
}