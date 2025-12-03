
UCLASS(Abstract)
class AGrapplePointSpline : AHazeActor
{
	access readonly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UGrapplePointComponent GrapplePointZoe;
	default GrapplePointZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default GrapplePointZoe.bVisualizeComponent = false;

	UPROPERTY(DefaultComponent, NotEditable)
	UGrapplePointComponent GrapplePointMio;
	default GrapplePointMio.UsableByPlayers = EHazeSelectPlayer::Mio;
	default GrapplePointMio.bVisualizeComponent = false;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent EditorIcon;
	default EditorIcon.RelativeLocation = FVector(0.0, 0.0, 125.0);

	UPROPERTY(DefaultComponent, Attach = GrapplePointMio)
	UGrapplePointDrawComponent MioDrawComp;

	UPROPERTY(DefaultComponent, Attach = GrapplePointZoe)
	UGrapplePointDrawComponent ZoeDrawComp;
#endif

	UPROPERTY(EditAnywhere, Meta = (ShowOnlyInnerProperties))
	FGrapplePointTargetableSettings GrappleSettings;

	UPROPERTY(EditAnywhere, Category = "Grapple Settings", Meta = (EditCondition = "false", EditConditionHides))
	bool bConvertedSettings = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Grapple Settings")
	access:readonly
	EHazeSelectPlayer UsableByPlayers;
	default UsableByPlayers = EHazeSelectPlayer::Both;

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;
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

		switch (UsableByPlayers)
		{
			case EHazeSelectPlayer::Both:
				GrapplePointMio.UsableByPlayers = EHazeSelectPlayer::Mio;
				GrapplePointZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;
				break;

			case EHazeSelectPlayer::Mio:
				GrapplePointMio.UsableByPlayers = EHazeSelectPlayer::Mio;
				GrapplePointZoe.UsableByPlayers = EHazeSelectPlayer::None;
				break;

			case EHazeSelectPlayer::Zoe:
				GrapplePointMio.UsableByPlayers = EHazeSelectPlayer::None;
				GrapplePointZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;
				break;

			case EHazeSelectPlayer::None:
			case EHazeSelectPlayer::Specified:
				GrapplePointMio.UsableByPlayers = EHazeSelectPlayer::None;
				GrapplePointZoe.UsableByPlayers = EHazeSelectPlayer::None;
				break;
		}
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
			UGrapplePointComponent Point;
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

#if EDITOR
class UGrapplePointSplineDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AGrapplePointSpline;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"Settings", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Visuals", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable", CategoryType = EScriptDetailCategoryType::Important);
	}
}
#endif
