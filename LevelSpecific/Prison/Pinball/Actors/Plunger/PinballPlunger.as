enum EPinballPlungerState
{
	Idle,
	PullBack,
	LaunchForward
};

UCLASS(Abstract, HideCategories = "Rendering Activation Collision Physics LOD Cooking Actor Tags LOD Navigation LevelInstance")
class APinballPlunger : AHazeActor
{
#if !RELEASE
	default PrimaryActorTick.bStartWithTickEnabled = true;
#else
	default PrimaryActorTick.bStartWithTickEnabled = false;
#endif

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default RootComp.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent SkeletalMeshComp;
	default SkeletalMeshComp.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UPinballPlungerComponent PlungerComp;

	UPROPERTY(DefaultComponent, Attach = PlungerComp)
	UStaticMeshComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = PlungerComp)
	UStaticMeshComponent PlungerMesh;

	UPROPERTY(DefaultComponent, Attach = PlungerComp)
	USpotLightComponent SpotLight;

	default CollisionComp.bHiddenInGame = true;
	default CollisionComp.bBlockCollisionOnDisable = false;

	UPROPERTY(DefaultComponent)
	UHackablePinballResponseComponent ResponseComp;
	default ResponseComp.InputSide = EHackablePinballInputSide::Both;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPinballLauncherComponent LauncherComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UPinballPlungerIdleCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UPinballPlungerLaunchForwardCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UPinballPlungerPullBackCapability);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 3000;

	UPROPERTY(DefaultComponent)
	UPinballBlockFollowComponent BlockFollowComp;

	UPROPERTY(DefaultComponent, Attach = PlungerComp)
	UPinballPredictionRecordTransformComponent PredictionRecordTransformComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalLogTransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UPinballTemporalLogSubframeTransformLoggerComponent TemporalLogSubframeTransformLoggerComp;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Plunger")
	bool bHideWhenDisabled = false;

	UPROPERTY(EditAnywhere, Category = "Dimensions")
	float Radius = 135;

	UPROPERTY(EditAnywhere, Category = "Dimensions")
	float ExtraSweepDistance = 150.0;

	UPROPERTY(EditAnywhere, Category = "Dimensions")
	float PlungerSurfaceHeight = 40;

	/**
	 * How long the spring is when at 0 offset
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Dimensions", AdvancedDisplay)
	float SpringRelativeLocationZ = 350;

	/**
	 * How long the spring is when at 0 offset
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Dimensions", AdvancedDisplay)
	float IdleSpringLength = 350;

	UPROPERTY(EditAnywhere, Category = "Idle")
	bool bSpringBackToIdle = true;

	UPROPERTY(EditAnywhere, Category = "Idle", Meta = (EditCondition = "!bSpringBackToIdle", EditConditionHides))
	float IdleReturnDuration = 1;

	UPROPERTY(EditAnywhere, Category = "Idle", Meta = (EditCondition = "bSpringBackToIdle", EditConditionHides))
	float IdleReturnSpringStiffness = 500;

	UPROPERTY(EditAnywhere, Category = "Idle", Meta = (EditCondition = "bSpringBackToIdle", EditConditionHides))
	float IdleReturnSpringDamping = 0.2;

	UPROPERTY(EditAnywhere, Category = "Pull Back")
	float PullBackDistance = 500;

	UPROPERTY(EditAnywhere, Category = "Pull Back")
	float PullBackAcceleration = 500;

	UPROPERTY(EditAnywhere, Category = "Pull Back")
	float PullBackMaxSpeed = 500;

	UPROPERTY(EditAnywhere, Category = "Launch Forward")
	float LaunchForwardDistance = 50;

	UPROPERTY(EditDefaultsOnly)
	bool bShort = false;

	UPROPERTY(EditAnywhere, Category = "Launch Forward")
	float LaunchForwardAcceleration = 50000;

	UPROPERTY(EditAnywhere, Category = "Launch Forward")
	float LaunchForwardMaxSpeed = 50000;

	UPROPERTY(EditAnywhere, Category = "Launch Forward")
	float LaunchForwardHitEndBounceFactor = 0.1;

	UPROPERTY(EditAnywhere, Category = "Launch Forward|Lerp")
	float LaunchLocationMargin = 50;

	UPROPERTY(EditAnywhere, Category = "Launch Forward|Lerp")
	bool bLerpWhileLaunching = true;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float MinLaunchPower = 500;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float MaxLaunchPower = 4500;

	UPROPERTY(EditAnywhere, Category = "Launch")
	FRuntimeFloatCurve LaunchAlphaFromPullBackAlphaCurve;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Simulation")
	bool bSimulateHit = true;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (ClampMin = "-1.0", ClampMax = "1.0", EditCondition = "bSimulateHit", EditConditionHides))
	float SimulatedInput = 0;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (ClampMin = "0", ClampMax = "1.0", EditCondition = "bSimulateHit", EditConditionHides))
	float SimulatedPullBackAlpha = 1;

	UPROPERTY(EditInstanceOnly, Category = "Simulation", Meta = (ClampMin = "0", ClampMax = "5.0", EditCondition = "bSimulateHit", EditConditionHides))
	float SimulationDuration = 1;
#endif

	EPinballPlungerState State = EPinballPlungerState::Idle;
	uint LastApplyLocationFrame = 0;
	private float PlungerDistance_Internal;
	float PlungerSpeed;

	bool bIsHolding = false;

	float StartPullBackDistance;
	float StopPullBackDistance;
	float LaunchPowerAlpha;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(!Math::IsNearlyZero(ActorLocation.X))
		{
			FVector Location = ActorLocation;
			Location.X = 0;
			SetActorLocation(Location);
		}

		if(!Math::IsNearlyZero(ActorRotation.Pitch) || !Math::IsNearlyZero(ActorRotation.Yaw))
		{
			FRotator Rotation = ActorRotation;
			Rotation.Pitch = 0;
			Rotation.Yaw = 0;
			SetActorRotation(Rotation);
		}

		LaunchLocationMargin = Math::Clamp(LaunchLocationMargin, 0, Radius);

		PlungerComp.SetRelativeLocation(FVector::ZeroVector);

		if(PullBackDistance > IdleSpringLength)
		{
			float Diff = PullBackDistance - IdleSpringLength;
			SkeletalMeshComp.SetRelativeLocation(FVector(0, 0, SpringRelativeLocationZ - Diff));
		}
		else
		{
			SkeletalMeshComp.SetRelativeLocation(FVector(0, 0, SpringRelativeLocationZ));
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetPaddlePlayer());
		
		Pinball::GetManager().OnPinballPlungerPulledBack.AddUFunction(this, n"StartPullBack");
		Pinball::GetManager().OnPinballPlungerReleased.AddUFunction(this, n"StopPullBack");


	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("State", State)
			.Value("LastApplyLocationFrame", LastApplyLocationFrame)
			.Value("HasAppliedLocationThisFrame", HasAppliedLocationThisFrame())

			.Value("PlungerDistance", PlungerDistance)
			.Value("PlungerSpeed", PlungerSpeed)

			.Value("bIsHolding", bIsHolding)

			.Value("StartPullBackDistance", StartPullBackDistance)
			.Value("StopPullBackDistance", StopPullBackDistance)
			.Value("LaunchPowerAlpha", LaunchPowerAlpha)

			.Value("CurrentPullBackAlpha", GetCurrentPullBackAlpha())
			.Value("StopPullBackAlpha", GetStopPullBackAlpha())
			.Value("CurrentLaunchForwardAlpha", GetCurrentLaunchForwardAlpha())
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(bHideWhenDisabled)
		{
			auto ComponentsToHide = BP_GetComponentsToHideWhenDisabled();
			for(auto ComponentToHide : ComponentsToHide)
			{
				if(ComponentToHide == nullptr)
					continue;

				ComponentToHide.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(bHideWhenDisabled)
		{
			auto ComponentsToHide = BP_GetComponentsToHideWhenDisabled();
			for(auto ComponentToHide : ComponentsToHide)
			{
				if(ComponentToHide == nullptr)
					continue;

				ComponentToHide.AddComponentVisualsAndCollisionAndTickBlockers(this);
			}
		}
	}

	float GetPlungerDistance() const property
	{
		// While predicting, we use the relative location, since that is recorded, but the plunger distance is not
		if(Pinball::Prediction::IsInsidePredictionLoop())
			return PlungerComp.RelativeLocation.Z;

		return PlungerDistance_Internal;
	}

	void SetPlungerDistance(float InPlungerDistance) property
	{
		PlungerDistance_Internal = InPlungerDistance;
	}

	void ApplyLocation()
	{
		check(!HasAppliedLocationThisFrame());

		PlungerDistance = Math::Clamp(PlungerDistance, -PullBackDistance, LaunchForwardDistance);

		// Apply moved distance to component
		PlungerComp.SetRelativeLocation(FVector(0, 0, PlungerDistance));

		LastApplyLocationFrame = Time::FrameNumber;
	}

	bool HasAppliedLocationThisFrame() const
	{
		return LastApplyLocationFrame == Time::FrameNumber;
	}

	UFUNCTION()
	private void StartPullBack()
	{
		bIsHolding = true;
		StartPullBackDistance = PlungerDistance;
		UPinballPlungerEventHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	private void StopPullBack()
	{
		bIsHolding = false;
		UPinballPlungerEventHandler::Trigger_OnStopMoving(this);
	}

	bool SweepForBall(FVector BallLocation, float BallRadius, float PlungerStartDistance) const
	{
		const FVector StartLocation = ActorTransform.TransformPosition(FVector(0, 0, PlungerStartDistance));
		const FPlane StartPlane = FPlane(StartLocation, PlungerComp.UpVector);

		const float CurrentOffset = (BallRadius + PlungerSurfaceHeight + ExtraSweepDistance);
		const FVector CurrentLocation = PlungerComp.WorldLocation + (PlungerComp.UpVector * CurrentOffset);
		const FPlane CurrentPlane = FPlane(CurrentLocation, PlungerComp.UpVector);

#if !RELEASE
		TEMPORAL_LOG(this).Section("Sweep For Ball")
			.Plane("Start Plane", StartLocation, PlungerComp.UpVector, Color = FLinearColor::Red)
			.Value("Distance from Start Plane", StartPlane.PlaneDot(BallLocation))

			.Plane("Current Plane", CurrentLocation, PlungerComp.UpVector, Color = FLinearColor::Green)
			.Value("Distance from Current Plane", CurrentPlane.PlaneDot(BallLocation))

			.Value("Horizontal Distance", BallLocation.Dist2D(CurrentPlane.Origin, CurrentPlane.Normal))
		;
#endif

		const float DistanceToStartPlane = StartPlane.PlaneDot(BallLocation);
		if(DistanceToStartPlane < 0)
			return false;	// Below start plane

		const float DistanceToCurrentPlane = CurrentPlane.PlaneDot(BallLocation);
		if(DistanceToCurrentPlane > 0)
			return false;	// Above current plane

		const float Distance = BallLocation.Dist2D(PlungerComp.WorldLocation, CurrentPlane.Normal);

		if(Distance > Radius + BallRadius)
			return false;	// Too far away horizontally

		return true;
	}

	FVector GetFinalLaunchLocation(FVector BallLocation, float BallRadius) const
	{
		const FTransform FinalTransform = FTransform(FQuat::Identity, FVector::UpVector * LaunchForwardDistance) * ActorTransform;
		return GetLaunchLocation(FinalTransform, BallLocation, BallRadius);
	}

	FVector GetCurrentLaunchLocation(FVector BallLocation, float BallRadius) const
	{
		return GetLaunchLocation(PlungerComp.WorldTransform, BallLocation, BallRadius);
	}

	private FVector GetLaunchLocation(FTransform Transform, FVector BallLocation, float BallRadius) const
	{
		FVector RelativeLocation = Transform.InverseTransformPositionNoScale(BallLocation);
		RelativeLocation.X = 0;

		const float LaunchLocationRadius = Radius - LaunchLocationMargin;
		RelativeLocation.Y = Math::Clamp(RelativeLocation.Y, -LaunchLocationRadius, LaunchLocationRadius);
		RelativeLocation.Z = PlungerSurfaceHeight + BallRadius;

		return Transform.TransformPositionNoScale(RelativeLocation);
	}

	FVector GetLaunchDirection() const
	{
		return PlungerComp.UpVector;
	}

	/**
	 * Alpha of the current plunger position between resting position and the bottom of the plunger.
	 */
	UFUNCTION(BlueprintPure)
	float GetCurrentPullBackAlpha() const
	{
		return Math::GetPercentageBetweenClamped(0, -PullBackDistance, PlungerDistance);
	}

	/**
	 * Alpha of the plunger position where we stopped pulling back to between resting position and the bottom of the plunger.
	 * 0 is not pulled back at all
	 * 1 is fully back
	 */
	UFUNCTION(BlueprintPure)
	float GetStopPullBackAlpha() const
	{
		return Math::GetPercentageBetweenClamped(0, -PullBackDistance, StopPullBackDistance);
	}

	/**
	 * Alpha of the plunger position where we stopped pulling back to between the top and bottom of the plunger.
	 * 0 is where we stopped pulling back, where the launch starts
	 * 1 is all the way forward, where the launch ends
	 */
	UFUNCTION(BlueprintPure)
	float GetCurrentLaunchForwardAlpha() const
	{
		return Math::GetPercentageBetweenClamped(StopPullBackDistance, LaunchForwardDistance, PlungerDistance);
	}

	float GetLaunchPower(float Alpha) const
	{
		float LaunchAlpha = LaunchAlphaFromPullBackAlphaCurve.GetFloatValue(Alpha);	// Base the launch power on the distance we released at
		return Math::Lerp(MinLaunchPower, MaxLaunchPower, LaunchAlpha);
	}

	float GetPlungerMoveDistance() const
	{
		return PlungerDistance - StopPullBackDistance;
	}

	float GetPlungerOffset() const
	{
		if(PullBackDistance > IdleSpringLength)
		{
			float Diff = PullBackDistance - IdleSpringLength;
			return PlungerDistance + Diff;
		}
		else
		{
			return PlungerDistance;
		}
	}

	UFUNCTION(BlueprintEvent)
	TArray<UPrimitiveComponent> BP_GetComponentsToHideWhenDisabled() { return TArray<UPrimitiveComponent>(); }
};

class UPinballPlungerComponent : USceneComponent
{
};

#if EDITOR
class UPinballPlungerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballPlungerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		APinballPlunger Plunger = Cast<APinballPlunger>(Component.Owner);
		const UPinballPlungerComponent PlungerComp = Cast<UPinballPlungerComponent>(Component);

		const FVector ExtraSweepLocation = Plunger.ActorTransform.TransformPositionNoScale(FVector::UpVector * Plunger.ExtraSweepDistance);
		DrawCircle(ExtraSweepLocation, Plunger.Radius, FLinearColor::Yellow, 3, PlungerComp.UpVector);

		const FVector SurfaceLocation = Plunger.PlungerComp.WorldTransform.TransformPositionNoScale(FVector::UpVector * Plunger.PlungerSurfaceHeight);
		DrawCircle(SurfaceLocation, Plunger.Radius / 2, FLinearColor::Red, 3, PlungerComp.UpVector);

		const FVector PullBackLocation = Plunger.ActorTransform.TransformPositionNoScale(FVector::UpVector * -Plunger.PullBackDistance);
		DrawCircle(PullBackLocation, Plunger.Radius, FLinearColor::Red, 3, PlungerComp.UpVector);

		const FVector LaunchForwardLocation = Plunger.ActorTransform.TransformPositionNoScale(FVector::UpVector * Plunger.LaunchForwardDistance);
		DrawCircle(LaunchForwardLocation, Plunger.Radius, FLinearColor::Green, 3, PlungerComp.UpVector);
		DrawCircle(LaunchForwardLocation, Plunger.Radius - Plunger.LaunchLocationMargin, FLinearColor::Purple, 3, PlungerComp.UpVector);

		DrawLine(PullBackLocation, LaunchForwardLocation, FLinearColor::Yellow, 3);

		if(Plunger.bSimulateHit)
		{
			SimulateHit(Plunger);
		}
		else
		{
			// Draw Plunger Location
			DrawCircle(PlungerComp.WorldLocation, Plunger.Radius, FLinearColor::Yellow, 3, PlungerComp.UpVector);
		}
	}

	private void SimulateHit(APinballPlunger Plunger) const
	{
		const float StopPullBackDistance = -Math::Lerp(0, Plunger.PullBackDistance, Plunger.SimulatedPullBackAlpha);
		FVector PlayerLocation = Plunger.GetFinalLaunchLocation(Plunger.PlungerComp.WorldLocation, MagnetDrone::Radius);

		DrawWireSphere(PlayerLocation, MagnetDrone::Radius, FLinearColor::DPink);

		// Draw Plunger Location
		DrawCircle(Plunger.PlungerComp.WorldLocation + Plunger.PlungerComp.UpVector * StopPullBackDistance, Plunger.Radius, FLinearColor::Yellow, 3, Plunger.PlungerComp.UpVector);

		const FVector LaunchDirection = Plunger.GetLaunchDirection();

		DrawArrow(PlayerLocation, PlayerLocation + LaunchDirection * 500, FLinearColor::Red, 20, 3, true);

		FVector Impulse = LaunchDirection * Plunger.GetLaunchPower(Plunger.SimulatedPullBackAlpha);

		Pinball::AirMoveSimulation::VisualizePath(this, PlayerLocation, Impulse, Plunger.LauncherComp, Plunger.SimulatedInput, FLinearColor::Green, Plunger.SimulationDuration);
	}
};
#endif