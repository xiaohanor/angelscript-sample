enum EIslandLockPickingPuzzleBoltMoveType
{
	None,
	Normal,
	Fail
}

event void FIslandLockPickingCompletedEvent();

UCLASS(Abstract)
class AIslandLockPickingPuzzleBolt : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PanelCover;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProgressBarParent;

	UPROPERTY(DefaultComponent, Attach = PanelCover)
	USceneComponent PanelCoverAttachComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UIslandLockPickingPuzzleBoltVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditInstanceOnly)
	AIslandGrenadeLockListener Listener;

	UPROPERTY(EditDefaultsOnly)
	float MovementDistancePerStep = 400.0;

	UPROPERTY(EditDefaultsOnly)
	float MovementDistanceFinalStep = 400.0;

	UPROPERTY(EditDefaultsOnly)
	float CooldownUntilReset = 3.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve NormalMoveCurve;
	default NormalMoveCurve.AddDefaultKey(0.0, 0.0);
	default NormalMoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	float NormalMovementDuration = 1.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve FailMoveCurve;
	default FailMoveCurve.AddDefaultKey(0.0, 0.0);
	default FailMoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	float FailMovementSpeed = 800.0;

	UPROPERTY(EditDefaultsOnly)
	float FailMaxAlphaWhenNotSynced = 0.5;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve StartPullApartMoveCurve;
	default StartPullApartMoveCurve.AddDefaultKey(0.0, 0.0);
	default StartPullApartMoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	float StartPullApartMovementDuration = 0.5;

	UPROPERTY(EditDefaultsOnly)
	float StartPullApartMovementDistance = 50.0;

	UPROPERTY(EditDefaultsOnly)
	float WaitingForFinishPullApartDuration = 2.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve FinishPullApartMoveCurve;
	default FinishPullApartMoveCurve.AddDefaultKey(0.0, 0.0);
	default FinishPullApartMoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	float FinishPullApartMovementDuration = 0.5;

	UPROPERTY(EditDefaultsOnly)
	float FinishPullApartMovementDistance = 50.0;

	UPROPERTY(EditDefaultsOnly)
	float PanelCoverMoveLength = 380.0;

	UPROPERTY(EditDefaultsOnly)
	float PanelCoverMoveAcceleration = 5000.0;

	UPROPERTY(EditInstanceOnly)
	TArray<AIslandLockPickingPuzzlePin> ConnectedPins;

	UPROPERTY(EditInstanceOnly)
	AActor PullApartActor;

	UPROPERTY(EditInstanceOnly)
	AIslandLockPickingPuzzleBolt OtherBolt;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel MoveBoltPanel;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PullApartPanel;

	UPROPERTY(EditInstanceOnly)
	AIslandGrenadeLock GrenadeLock;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer ControlSidePlayer = EHazePlayer::Mio;

	UPROPERTY()
	FIslandLockPickingCompletedEvent OnCompleted;

	private FVector StartLocation;
	private FVector EndLocation;
	EIslandLockPickingPuzzleBoltMoveType MoveType = EIslandLockPickingPuzzleBoltMoveType::None;
	private float TimeOfStartMove = -100.0;
	private int AmountOfMoves = 0;
	private FHazeAcceleratedVector AcceleratedPanelCoverLocation;
	private bool bPanelIsMoving = false;
	private bool bPanelIsDone = false;
	private TOptional<float> TimeOfStartCooldown;
	private TArray<UStaticMeshComponent> ProgressBars;
	FVector PanelStartRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetPlayer(ControlSidePlayer));
		PanelStartRelativeLocation = PanelCover.RelativeLocation;
		
		AcceleratedPanelCoverLocation.SnapTo(PanelCoverTargetRelativeLocation);
		PanelCover.RelativeLocation = AcceleratedPanelCoverLocation.Value;

		for(AIslandLockPickingPuzzlePin Pin : ConnectedPins)
		{
			Pin.Bolt = this;
		}

		MoveBoltPanel.OnOvercharged.AddUFunction(this, n"OnCompletedMoveBoltPanel");
		if(Listener != nullptr)
			Listener.OnCompleted.AddUFunction(this, n"OnListenerCompleted");

		if(MoveBoltPanel != PullApartPanel && PullApartPanel != nullptr)
		{
			PullApartPanel.DisablePanel();
		}

		if(GrenadeLock != nullptr)
		{
			GrenadeLock.AttachToComponent(PanelCoverAttachComp);
		}

		ProgressBarParent.GetChildrenComponentsByClass(UStaticMeshComponent, false, ProgressBars);
	}

	UFUNCTION()
	private void OnCompletedMoveBoltPanel()
	{
		if(IsMoving())
			return;

		if(PinsCompleted())
			return;

		if(!HasControl())
			return;

		CrumbStartNormalMove();
	}

	UFUNCTION()
	private void OnListenerCompleted()
	{
		SetActorTickEnabled(false);
		SetProgressBarAlpha(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleMove();
		HandlePanelCoverMove(DeltaTime);
		HandleProgressBar();
	}

	void Internal_OnCompleted()
	{
		BP_OnCompleted();
		OnCompleted.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnCompleted() {}

	UFUNCTION(CrumbFunction)
	private void CrumbStartNormalMove()
	{
		if(!HasControl())
			return;

		FVector FutureStartLocation = ActorLocation;

		float Distance = MovementDistancePerStep;
		if(PinsCompleted())
			Distance = MovementDistanceFinalStep;

		FVector FutureEndLocation = FutureStartLocation + ActorForwardVector * Distance;
		CrumbStartMove(EIslandLockPickingPuzzleBoltMoveType::Normal, FutureStartLocation, FutureEndLocation, AmountOfMoves + 1);
	}

	void StartFailMove()
	{
		if(!HasControl())
			return;

		FVector FutureStartLocation = ActorLocation;
		
		float Distance = MovementDistancePerStep * AmountOfMoves;
		if(PinsCompleted())
			Distance = Distance - MovementDistancePerStep + MovementDistanceFinalStep;

		FVector FutureEndLocation = EndLocation - ActorForwardVector * Distance;
		CrumbStartMove(EIslandLockPickingPuzzleBoltMoveType::Fail, FutureStartLocation, FutureEndLocation, 0);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartMove(EIslandLockPickingPuzzleBoltMoveType In_MoveType, FVector In_StartLocation, FVector In_EndLocation, int In_AmountOfMoves)
	{
		StartLocation = In_StartLocation;
		EndLocation = In_EndLocation;
		AmountOfMoves = In_AmountOfMoves;

		MoveType = In_MoveType;
		TimeOfStartMove = Time::GetGameTimeSeconds();

		FIslandLockPickingPuzzleBoltMoveEffectParams Params;
		Params.Bolt = this;
		Params.MoveType = MoveType;
		UIslandLockPickingPuzzleBoltEffectHandler::Trigger_OnBoltStartMoving(this, Params);
		TimeOfStartCooldown.Reset();
	}

	void StopMove()
	{
		if(IsNormalMove())
			TimeOfStartCooldown.Set(Time::GetGameTimeSeconds());

		if(IsFailMove() && bPanelIsDone)
		{
			StartMovingPanel();
		}

		if(IsNormalMove() && PinsCompleted())
		{
			if(MoveBoltPanel != PullApartPanel)
			{
				StartMovingPanel();
			}
		}

		FIslandLockPickingPuzzleBoltMoveEffectParams Params;
		Params.Bolt = this;
		Params.MoveType = MoveType;
		UIslandLockPickingPuzzleBoltEffectHandler::Trigger_OnBoltStopMoving(this, Params);

		MoveType = EIslandLockPickingPuzzleBoltMoveType::None;
	}

	void HandleMove()
	{
		if(HasControl())
		{
			if(TimeOfStartCooldown.IsSet() && Time::GetGameTimeSince(TimeOfStartCooldown.Value) > CooldownUntilReset)
			{
				StartFailMove();
				return;
			}
		}

		if(!IsMoving())
			return;

		FVector Location = GetNewLocation();
		if(HasControl() && IsNormalMove() && !ActorLocation.Equals(Location))
		{
			UPrimitiveComponent Comp = GetClosestPinComponent();
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Comp);
			FBox Bounds = Mesh.GetBoundingBoxRelativeToOwner();
			FVector ScaledExtents = Bounds.Extent * ActorScale3D;
			Trace.UseBoxShape(ScaledExtents, ActorQuat);
			FHitResult Hit = Trace.QueryTraceComponent(ActorLocation, Location);
			if(Hit.bBlockingHit)
			{
				ActorLocation = Hit.Location + Hit.Normal * 0.125;
				StartFailMove();

				FIslandLockPickingPuzzleBoltBoltHitPinEffectParams Params;
				Params.Bolt = this;
				Params.Pin = Cast<AIslandLockPickingPuzzlePin>(Hit.Actor);
				UIslandLockPickingPuzzleBoltEffectHandler::Trigger_OnBoltHitPin(this, Params);
				return;
			}
		}

		ActorLocation = Location;
	}

	void StartMovingPanel()
	{
		bPanelIsMoving = true;
		FIslandLockPickingPuzzleBoltGenericEffectParams Params;
		Params.Bolt = this;
		UIslandLockPickingPuzzleBoltEffectHandler::Trigger_OnPanelStartMoving(this, Params);
		MoveBoltPanel.DisablePanel();
	}

	void HandlePanelCoverMove(float DeltaTime)
	{
		if(!bPanelIsMoving)
			return;

		AcceleratedPanelCoverLocation.ThrustTo(PanelCoverTargetRelativeLocation, PanelCoverMoveAcceleration, DeltaTime);
		PanelCover.RelativeLocation = AcceleratedPanelCoverLocation.Value;
		if(AcceleratedPanelCoverLocation.Value.Equals(PanelCoverTargetRelativeLocation))
		{
			bPanelIsDone = PinsCompleted();
			if (bPanelIsDone)
				MoveBoltPanel.DisablePanel();
			else
				MoveBoltPanel.EnablePanel();
			bPanelIsMoving = false;
			FIslandLockPickingPuzzleBoltGenericEffectParams Params;
			Params.Bolt = this;
			UIslandLockPickingPuzzleBoltEffectHandler::Trigger_OnPanelStopMoving(this, Params);
		}
	}

	void HandleProgressBar()
	{
		float Alpha = GetProgressBarAlpha();
		SetProgressBarAlpha(Alpha);
	}

	void SetProgressBarAlpha(float Alpha)
	{
		for(UStaticMeshComponent Current : ProgressBars)
		{
			Current.SetScalarParameterValueOnMaterials(n"FillPercentage", Alpha);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetProgressBarAlpha()
	{
		if(!TimeOfStartCooldown.IsSet())
			return 0.0;

		return 1.0 - Math::Saturate(Time::GetGameTimeSince(TimeOfStartCooldown.Value) / CooldownUntilReset);
	}

	FVector GetNewLocation()
	{
		float MoveAlpha = 0.0;
		switch(MoveType)
		{
			case EIslandLockPickingPuzzleBoltMoveType::Normal:
			{
				MoveAlpha = GetCurrentMoveAlpha(NormalMovementDuration, NormalMoveCurve);
				break;
			}
			case EIslandLockPickingPuzzleBoltMoveType::Fail:
			{
				float Distance = StartLocation.Distance(EndLocation);
				float FailDuration = Distance / FailMovementSpeed;
				MoveAlpha = GetCurrentMoveAlpha(FailDuration, FailMoveCurve);
				break;
			}
			default:
				devError("Forgot to add case!");
		}	

		if(MoveAlpha == 1.0)
			StopMove();
		
		return Math::Lerp(StartLocation, EndLocation, MoveAlpha);
	}

	float GetCurrentMoveAlpha(float Duration, FRuntimeFloatCurve Curve) const
	{
		float TimeSince = Time::GetGameTimeSince(TimeOfStartMove);
		float MoveDuration = Duration;
		float Alpha = TimeSince / MoveDuration;
		Alpha = Math::Saturate(Alpha);
		return Curve.GetFloatValue(Alpha);
	}

	UPrimitiveComponent GetClosestPinComponent() const
	{
		FBox Bounds = GetActorLocalBoundingBox(true);
		float Distance = Bounds.Extent.X * ActorScale3D.X;
		FVector Origin = ActorLocation + ActorForwardVector * Distance;

		float ClosestSqrDistance = MAX_flt;
		UPrimitiveComponent ClosestPinComp = nullptr;
		for(AIslandLockPickingPuzzlePin Pin : ConnectedPins)
		{
			float DistSqr = Origin.DistSquared(Pin.TopCollision.WorldLocation);
			if(DistSqr < ClosestSqrDistance)
			{
				ClosestSqrDistance = DistSqr;
				ClosestPinComp = Pin.TopCollision;
			}

			DistSqr = Origin.DistSquared(Pin.BottomCollision.WorldLocation);
			if(DistSqr < ClosestSqrDistance)
			{
				ClosestSqrDistance = DistSqr;
				ClosestPinComp = Pin.BottomCollision;
			}
		}

		return ClosestPinComp;
	}

	bool IsMoving() const
	{
		return MoveType != EIslandLockPickingPuzzleBoltMoveType::None;
	}

	bool IsNormalMove() const
	{
		return MoveType == EIslandLockPickingPuzzleBoltMoveType::Normal;
	}

	bool IsFailMove() const
	{
		return MoveType == EIslandLockPickingPuzzleBoltMoveType::Fail;
	}

	bool PinsCompleted() const
	{
		return AmountOfMoves == ConnectedPins.Num();
	}

	FVector GetPanelCoverTargetRelativeLocation() const property
	{
		if(PinsCompleted())
			return PanelStartRelativeLocation + FVector::ForwardVector * PanelCoverMoveLength;

		return PanelStartRelativeLocation;
	}
}

#if EDITOR
class UIslandLockPickingPuzzleBoltVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandLockPickingPuzzleBoltVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandLockPickingPuzzleBoltVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Bolt = Cast<AIslandLockPickingPuzzleBolt>(Component.Owner);
		FBox Box = Bolt.PanelCover.GetBoundingBoxRelativeToOwner();
		FVector Location = Box.Center;
		FVector Delta = FVector::ForwardVector * Bolt.PanelCoverMoveLength;
		DrawWireBox(Bolt.ActorTransform.TransformPosition(Location + Delta), Box.Extent * Bolt.ActorScale3D, Bolt.ActorQuat, FLinearColor::Green, 3.0);
		DrawWireBox(Bolt.ActorTransform.TransformPosition(Location), Box.Extent * Bolt.ActorScale3D, Bolt.ActorQuat, FLinearColor::Red, 3.0);
	}
}
#endif