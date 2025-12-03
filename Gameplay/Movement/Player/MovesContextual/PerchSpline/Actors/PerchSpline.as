event void FOnPlayerPerchSplineGroundedStateChange(AHazePlayerCharacter Player);

UCLASS(Abstract)
class APerchSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent, NotEditable, Attach = RootComp)
	UPerchPointSplineComponent PerchSplineMio;
	UPROPERTY(DefaultComponent, NotEditable, Attach = RootComp)
	UPerchPointSplineComponent PerchSplineZoe;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent EditorBillboard;
	default EditorBillboard.RelativeLocation = FVector(0.0, 0.0, 125.0);

	UPROPERTY(DefaultComponent, Attach = PerchSplineMio)
	UPerchPointDrawComponent DrawComp;
#endif

	UPROPERTY(DefaultComponent, Attach = Spline)
	UPerchEnterByZoneComponent PerchEnterZoneMio;
	default PerchEnterZoneMio.bVisualizeComponent = false;
	default PerchEnterZoneMio.bUseNameToFindComponent = true;
	default PerchEnterZoneMio.NameToUse = n"PerchSplineMio";

	UPROPERTY(DefaultComponent, Attach = Spline)
	UPerchEnterByZoneComponent PerchEnterZoneZoe;
	default PerchEnterZoneZoe.bVisualizeComponent = false;
	default PerchEnterZoneZoe.bUseNameToFindComponent = true;
	default PerchEnterZoneZoe.NameToUse = n"PerchSplineZoe";

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	/*
	 * Should perching be allowed on point
	 * If false then interact will move player to the point and exit with input based speed rather then perching
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAllowPerch = true;

	//Should you be able to cancel by giving input away from the spline
	// UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bAllowPerch", EditConditionHides))
	// bool bSoftPerchLock = false;

	//Do we allow cancelling when perching on point.
	UPROPERTY(EditAnywhere, Category = "Settings", EditConst, AdvancedDisplay)
	bool bAllowCancel = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAllowGrappleToPoint = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	bool bAllowAutoJumpTo = true;

	/**
	 * Allow the player to leave the perch spline by jumping off sideways left and right.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	bool bAllowSidewaysJumpOff = true;

	/**
	 * We only trigger an automatic jumpto when the player is in range and the movement input is
	 * within this angle of the direction to the perch point.
	 * Larger angles make it easier to jump to the perch point, but can cause unexpected behavior for the player.
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaximumHorizontalJumpToAngle = 20.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, AdvancedDisplay, Category = "Settings")
	EPerchPointLandingAssistStrength LandingAssistStrength = EPerchPointLandingAssistStrength::Default;

	//If the perchspline length is being modulated in runtime then enable this, it will then check player current spline distance vs spline length and kick the player off if invalid
	UPROPERTY(EditInstanceOnly, AdvancedDisplay, Category = "Settings")
	bool bValidatePlayerSplineDistanceAndSplineLength = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EGrappleImpactType ImpactType;

	/*
	 * This Range will be added inbetween ActivationRange and AdditionalVisibleRange
	 * While in this range a grapple to target will be triggered rather then PerchJumpTo
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float AdditionalGrappleRange = 1250.0;

	//Range at which the point will be actionable
	UPROPERTY(EditAnywhere, Category = "Settings")
	float ActivationRange = 450.0;

	/*
	 * Allows contextual moves to be visible before they are actionable
	 * At 0, the point will be actionable as soon as you get in range
	 * At 500, the point will be visible for 500 units before you can activate the point
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float AdditionalVisibleRange = 750.0;

	/*
	 * Minimum Range to enforce
	 * 0 = no minium range
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinimumRange = 0.0;

	//- Will visualize ranges even when not selected in editor
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAlwaysVisualizeRanges = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bMoveActorPivotToFirstSplinePoint = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UPlayerPerchSettings PerchSettings;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset PerchCameraSetting;

	UPROPERTY(EditAnywhere, Category = "Settings|Enter/Exit")
	FPerchSplineEnterZoneSettings StartZoneSettings;

	UPROPERTY(EditAnywhere, Category = "Settings|Enter/Exit")
	FPerchSplineEnterZoneSettings EndZoneSettings;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UAudioPlayerFootTraceSettings FootTraceSettings;
	
	// Always grapple to 
	UPROPERTY(EditAnywhere, Category = "Settings|Grapple", Meta = (EditCondition = "bAllowGrappleToPoint", EditConditionHides))
	bool bAlwaysGrappleToStaticPoint = false;

	UPROPERTY(EditAnywhere, Category = "Settings|Grapple", Meta = (EditCondition = "bAllowGrappleToPoint && bAlwaysGrappleToStaticPoint", EditConditionHides))
	TPerPlayer<float> GrappleToSplineDistance;

	/* Whether to disable the interaction by default when it begins play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Targetable", meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the interaction begins play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Targetable", meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	UPROPERTY(EditAnywhere, Category = "Targetable")
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	EAirActivationSettings AirActivationSettings = EAirActivationSettings::ActivateInAirAndGround;

	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	EHeightActivationSettings HeightActivationSettings = EHeightActivationSettings::ActivateBelowAndAbove;

	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	bool bTestCollision = false;

	UPROPERTY(EditAnywhere, Category = "Targetable|Modified World Up")
	bool bShouldValidateWorldUp = false;

	UPROPERTY(EditAnywhere, Category = "Targetable|Modified World Up", meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0", EditCondition = "bShouldValidateWorldUp"))
	float UpVectorCutOffAngle = 15.0;

	UPROPERTY(EditAnywhere, Category = "Targetable|Modified World Up")
	bool bShowWorldUpCutoff = false;

	UPROPERTY(EditAnywhere, Category = "Network", AdvancedDisplay)
	bool bCrumbRelativeToSpline = false;

	// Ignore the perch spline's movement for the purposes of entering it
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bIgnorePerchMovementDuringEnter = false;

	UPROPERTY()
	FOnPlayerStartedPerchingOnPointEventSignature OnPlayerStartedPerchingEvent;
	UPROPERTY()
	FOnPlayerStoppedPerchingOnPointEventSignature OnPlayerStoppedPerchingEvent;

	UPROPERTY()
	FOnPlayerPerchSplineGroundedStateChange OnPlayerJumpedOnSpline;

	UPROPERTY()
	FOnPlayerPerchSplineGroundedStateChange OnPlayerLandedOnSpline;

	private TArray<UPerchPointSplineComponent> PerchPoints;
	private TArray<UPerchEnterByZoneComponent> EnterZones;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Spline.SplinePoints.Num() != 0 && bMoveActorPivotToFirstSplinePoint)
		{
			FVector SplinePointOrigin = Spline.SplinePoints[0].RelativeLocation;
			if (!SplinePointOrigin.IsNearlyZero())
			{
				for (FHazeSplinePoint& SplinePoint : Spline.SplinePoints)
					SplinePoint.RelativeLocation -= SplinePointOrigin;

				RootComponent.Modify();
				RootComponent.SetWorldLocation(Spline.WorldTransform.TransformPosition(SplinePointOrigin));
				Spline.Modify();
				Spline.SetRelativeLocation(FVector::ZeroVector);
			}
		}

		Spline.UpdateSpline();

		TArray<UPerchPointSplineComponent> EditorPoints;
		GetComponentsByClass(EditorPoints);

		for (auto PerchPoint : EditorPoints)
		{
			PerchPoint.bHasConnectedSpline = true;
			PerchPoint.ConnectedSpline = this;

			PerchPoint.ActivationRange = ActivationRange;
			PerchPoint.AdditionalVisibleRange = AdditionalVisibleRange;
			PerchPoint.AdditionalGrappleRange = AdditionalGrappleRange;
			PerchPoint.MaximumHorizontalJumpToAngle = MaximumHorizontalJumpToAngle;
			PerchPoint.LandingAssistStrength = LandingAssistStrength;
			PerchPoint.MinimumRange = MinimumRange;
			PerchPoint.bAllowPerch = bAllowPerch;
			PerchPoint.PerchSettings = PerchSettings;
			PerchPoint.PerchCameraSetting = PerchCameraSetting;
			PerchPoint.bStartDisabled = bStartDisabled;
			PerchPoint.StartDisabledInstigator = StartDisabledInstigator;
			PerchPoint.AirActivationSettings = AirActivationSettings;
			PerchPoint.HeightActivationSettings = HeightActivationSettings;
			PerchPoint.bTestCollision = bTestCollision;
			PerchPoint.bShouldValidateWorldUp = bShouldValidateWorldUp;
			PerchPoint.UpVectorCutOffAngle = UpVectorCutOffAngle;
			PerchPoint.bShowWorldUpCutoff = bShowWorldUpCutoff;
			PerchPoint.bAlwaysVisualizeRanges = bAlwaysVisualizeRanges;
			PerchPoint.bAllowGrappleToPoint = bAllowGrappleToPoint;
			PerchPoint.bAllowAutoJumpTo = bAllowAutoJumpTo;
			PerchPoint.bIgnorePerchMovementDuringEnter = bIgnorePerchMovementDuringEnter;
			PerchPoint.bGrappleToStaticSplineDistance = bAlwaysGrappleToStaticPoint;
			PerchPoint.ImpactEffectType = ImpactType;

			if (PerchPoint == PerchSplineMio)
				PerchPoint.GrappleStaticSplineDistance = GrappleToSplineDistance[EHazePlayer::Mio];
			else
				PerchPoint.GrappleStaticSplineDistance = GrappleToSplineDistance[EHazePlayer::Zoe];

			if (PerchPoint.bGrappleToStaticSplineDistance)
			{
				FTransform PointTransform = Spline.GetWorldTransformAtSplineDistance(PerchPoint.GrappleStaticSplineDistance);
				PointTransform.SetScale3D(FVector::OneVector);
				PerchPoint.WorldTransform = PointTransform;
			}

			switch (UsableByPlayers)
			{
				case EHazeSelectPlayer::Both:
					if (PerchPoint == PerchSplineMio)
						PerchPoint.UsableByPlayers = EHazeSelectPlayer::Mio;
					else
						PerchPoint.UsableByPlayers = EHazeSelectPlayer::Zoe;
				break;
				case EHazeSelectPlayer::Mio:
					if (PerchPoint == PerchSplineMio)
						PerchPoint.UsableByPlayers = EHazeSelectPlayer::Mio;
					else
						PerchPoint.UsableByPlayers = EHazeSelectPlayer::None;
				break;
				case EHazeSelectPlayer::Zoe:
					if (PerchPoint == PerchSplineMio)
						PerchPoint.UsableByPlayers = EHazeSelectPlayer::None;
					else
						PerchPoint.UsableByPlayers = EHazeSelectPlayer::Zoe;
				break;
				case EHazeSelectPlayer::None:
				case EHazeSelectPlayer::Specified:
					PerchPoint.UsableByPlayers = EHazeSelectPlayer::None;
				break;
			}
		}

		UpdateEnterZones();
	}

	void UpdateEnterZones()
	{
		TArray<UPerchEnterByZoneComponent> EditorZones;
		GetComponentsByClass(EditorZones);

		float EnterBoxRange = ActivationRange + AdditionalVisibleRange;
		if (bAllowGrappleToPoint)
			EnterBoxRange += AdditionalGrappleRange;

		for (auto Zone : EditorZones)
		{
			Zone.RelativeLocation = Spline.ComputedSpline.Bounds.Center;
			Zone.ChangeShape(FHazeShapeSettings::MakeBox(Spline.ComputedSpline.Bounds.Extent + FVector(500.0 + EnterBoxRange)));
		}		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(PerchPoints);

		for (auto PerchPoint : PerchPoints)
		{
			PerchPoint.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerching");
			PerchPoint.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerching");
		}

		GetComponentsByClass(EnterZones);

		PerchEnterZoneMio.DisableTriggerForPlayer(Game::Zoe, this);
		PerchEnterZoneZoe.DisableTriggerForPlayer(Game::Mio, this);

		for (auto Zone : EnterZones)
		{
			Zone.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredZone");
			Zone.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeftZone");
		}
	}

	UFUNCTION()
	private void OnPlayerEnteredZone(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
		{
			PerchSplineMio.SetEvaluationEnabled(true);
		}
		else
		{
			PerchSplineZoe.SetEvaluationEnabled(true);
		}
	}

	UFUNCTION()
	private void OnPlayerLeftZone(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
		{
			PerchSplineMio.SetEvaluationEnabled(false);
		}
		else
		{
			PerchSplineZoe.SetEvaluationEnabled(false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerStartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		OnPlayerStartedPerchingEvent.Broadcast(Player, PerchPoint);

		if(FootTraceSettings != nullptr)
			Player.ApplySettings(FootTraceSettings, this, EHazeSettingsPriority::Script);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerStoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchPoint);

		if(FootTraceSettings != nullptr)
			Player.ClearSettingsWithAsset(FootTraceSettings, this);
	}

	/*
	 * Will enable point for whichever player is set by "UsableByPlayers"
	 */
	UFUNCTION(Category ="Perch Spline Activation")
	void EnablePerchSpline(FInstigator Instigator)
	{
		for (UPerchPointSplineComponent PerchPoint : PerchPoints)
			PerchPoint.Enable(Instigator);

		for (UPerchEnterByZoneComponent Zone : EnterZones)
			Zone.EnableTrigger(Instigator);
	}

	UFUNCTION(Category ="Perch Spline Activation")
	void EnablePerchSplineAfterStartDisabled()
	{
		for (UPerchPointSplineComponent PerchPoint : PerchPoints)
			PerchPoint.EnableAfterStartDisabled();
	}

	//Will enable point for whichever player is referenced (will not affect other players access)
	UFUNCTION(Category = "Perch Spline Activation")
	void EnablePerchSplineForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
#if EDITOR			
			devCheck(Player.IsSelectedBy(UsableByPlayers),
				"Attempted to enable: " + Name + " For Player: " + Player.Name + " When that player is not set as usable for the actor");
#endif	
		
		for (UPerchPointSplineComponent PerchPoint : PerchPoints)
			PerchPoint.EnableForPlayer(Player, Instigator);
		for (UPerchEnterByZoneComponent Zone : EnterZones)
			Zone.EnableTriggerForPlayer(Player, Instigator);
	}

	/*
	 * Will Disable Spline for both players
	 */
	UFUNCTION(Category = "Perch Spline Activation")
	void DisablePerchSpline(FInstigator Instigator)
	{
		for (UPerchPointSplineComponent PerchPoint : PerchPoints)
			PerchPoint.Disable(Instigator);
		for (UPerchEnterByZoneComponent Zone : EnterZones)
			Zone.DisableTrigger(Instigator);
	}

	//Will disable spline for whichever player is referenced (will not affect other players access)
	UFUNCTION(Category = "Perch Spline Activation")
	void DisablePerchSplineForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		for (UPerchPointSplineComponent PerchPoint : PerchPoints)
			PerchPoint.DisableForPlayer(Player, Instigator);
		for (UPerchEnterByZoneComponent Zone : EnterZones)
			Zone.DisableTriggerForPlayer(Player, Instigator);
	}
}

class UPerchSplineDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = APerchSpline;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"Settings", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable", CategoryType = EScriptDetailCategoryType::Important);
	}
}

struct FPerchSplineEnterZoneSettings
{
	UPROPERTY()
	bool bAllowRunningOffEdge = false;
}