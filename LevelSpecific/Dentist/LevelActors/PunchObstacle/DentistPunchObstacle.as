#if !RELEASE
namespace DevTogglesDentist
{
	const FHazeDevToggleBool PrintPunchObstacleEvents;
};
#endif

UCLASS(Abstract)
class ADentistPunchObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PunchRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent, Attach = PunchRoot)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent, Attach = PunchRoot)
	UBoxComponent LaunchTrigger;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDentistPunchObstacleSimulationComponent SimulationComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Simulation", Meta = (ClampMin = "1"))
	int PunchesPerLoop = 1;

	UPROPERTY(EditAnywhere, Category = "Extend")
	FRuntimeFloatCurve ExtendCurve;

	UPROPERTY(EditAnywhere, Category = "Extend", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float ExtendDurationAlpha = 0.15;

	UPROPERTY(EditAnywhere, Category = "Extend")
	float ExtendDistance = 800.0;

	UPROPERTY(EditAnywhere, Category = "Retract")
	FRuntimeFloatCurve RetractCurve;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float VerticalVelocity = 500.0;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float HorizontalVelocity = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	FDentistToothApplyRagdollSettings RagdollSettings;

	bool bIsExtending = false;

	UPROPERTY()
	bool bDoCameraShake = true;

	int CurrentSimulationLoopCount = 0;
	int CurrentPunchLoopCount = 0;
	bool bHasStartedPunchingOut = false;
	bool bHasBounced = false;
	bool bHasStartedMovingBack = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SimulationComp.OnTickSimulationDelegate.BindUFunction(this, n"OnTickSimulation");

		MovementImpactCallbackComponent.OnAnyImpactByPlayer.AddUFunction(this, n"HandlePlayerImpact");

#if !RELEASE
		DevTogglesDentist::PrintPunchObstacleEvents.MakeVisible();
#endif
	}

	UFUNCTION()
	private void OnTickSimulation(float LoopTime, float LoopDuration, int LoopCount)
	{
		UpdateSimulationLocation(LoopTime, LoopDuration, LoopCount);
	}

	void UpdateSimulationLocation(float LoopTime, float LoopDuration, int LoopCount)
	{
		int PunchLoopCount;
		float PunchLoopAlpha;
		const FVector PunchLocation = GetRelativeLocationAtTime(
			LoopTime,
			LoopDuration,
			bIsExtending,
			PunchLoopCount,
			PunchLoopAlpha
		);

		PunchRoot.SetRelativeLocation(PunchLocation);

		// While simulating, loop count is -1
		if(LoopCount < 0)
			return;

		// On new loop, reset events
		if(CurrentSimulationLoopCount < LoopCount || CurrentPunchLoopCount < PunchLoopCount)
			OnNewLoop();

		CurrentSimulationLoopCount = LoopCount;
		CurrentPunchLoopCount = PunchLoopCount;

		TriggerEventsForAlpha(PunchLoopAlpha);
	}

	FVector GetRelativeLocationAtTime(
		float TimeSinceStart,
		float SimulationLoopDuration,
		bool&out bOutIsExtending,
		int&out OutPunchLoopCount,
		float&out OutPunchAlpha) const
	{
		const float SimulationLoopTime = Math::Wrap(TimeSinceStart, 0, SimulationLoopDuration);
		const float PunchLoopDuration = SimulationLoopDuration / PunchesPerLoop;
		const float PunchLoopAlpha = (SimulationLoopTime % PunchLoopDuration) / PunchLoopDuration;

		OutPunchLoopCount = Math::FloorToInt(SimulationLoopTime / PunchLoopDuration);
		OutPunchAlpha = PunchLoopAlpha;

		if(PunchLoopAlpha < ExtendDurationAlpha)
		{
			// Extending
			bOutIsExtending = true;

			const float ExtendAlpha = PunchLoopAlpha / ExtendDurationAlpha;
			const float CurrentValue = ExtendCurve.GetFloatValue(ExtendAlpha);
			return FVector::ForwardVector * Math::Lerp(0.0, ExtendDistance, CurrentValue);
		}
		else
		{
			// Retracting
			bOutIsExtending = false;

			const float RetractAlpha = Math::NormalizeToRange(PunchLoopAlpha, ExtendDurationAlpha, 1.0);
			const float CurrentValue = RetractCurve.GetFloatValue(RetractAlpha);
			return FVector::ForwardVector * Math::Lerp(ExtendDistance, 0.0, CurrentValue);
		}
	}

	void TriggerEventsForAlpha(float PunchLoopAlpha)
	{
		if(!bHasStartedPunchingOut)
		{
			UDentistPunchObstacleEventHandler::Trigger_OnStartPunchingOut(this);
			bHasStartedPunchingOut = true;

#if !RELEASE
			if(DevTogglesDentist::PrintPunchObstacleEvents.IsEnabled())
				Debug::DrawDebugString(MoveIntoPlayerShapeComp.WorldLocation, "Start Punching Out", FLinearColor::Green, 1, 2);
#endif
		}

		if(!bHasBounced && PunchLoopAlpha > (0.15 * 0.55))
		{
			UDentistPunchObstacleEventHandler::Trigger_OnBounced(this);
			bHasBounced = true;

			BP_CameraShakeOnBounce();

#if !RELEASE
			if(DevTogglesDentist::PrintPunchObstacleEvents.IsEnabled())
				Debug::DrawDebugString(MoveIntoPlayerShapeComp.WorldLocation, "Bounced", FLinearColor::Yellow, 1, 2);
#endif
		}

		if(!bHasStartedMovingBack && PunchLoopAlpha > 0.15)
		{
			UDentistPunchObstacleEventHandler::Trigger_OnStartMovingBack(this);
			bHasStartedMovingBack = true;

#if !RELEASE
			if(DevTogglesDentist::PrintPunchObstacleEvents.IsEnabled())
				Debug::DrawDebugString(MoveIntoPlayerShapeComp.WorldLocation + FVector(0, 0, 200), "Start Moving Back", FLinearColor::Red, 1, 2);
#endif
		}
	}

	void OnNewLoop()
	{
		// Trigger any events that didn't happen
		TriggerEventsForAlpha(1);

		// Reset events
		bHasStartedPunchingOut = false;
		bHasBounced = false;
		bHasStartedMovingBack = false;
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		if (!LaunchTrigger.IsOverlappingActor(Player))
			return;

		if (!bIsExtending)
			return;

		FVector Impulse = ActorForwardVector * HorizontalVelocity + FVector::UpVector * VerticalVelocity;

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		if(ResponseComp == nullptr)
			return;

		FDentistPunchObstacleEventData Params; //Johannes added for VO
		Params.Player = Player; //Johannes added for VO

		ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);
		UDentistPunchObstacleEventHandler::Trigger_OnPunchedPlayer(this, Params);
	}

	UFUNCTION(BlueprintEvent)
	void BP_CameraShakeOnBounce() {}
};

UCLASS(NotBlueprintable)
class UDentistPunchObstacleSimulationComponent : UDentistSimulationComponent
{
	default bLoopSimulation = true;
	default TickOrder = 90; // Before LaunchedBall

#if EDITOR
	TArray<ADentistLaunchedBall> HitBalls;

	void PrepareSimulation(ADentistSimulationLoop InSimulationLoop) override
	{
		Super::PrepareSimulation(InSimulationLoop);

		HitBalls.Reset();
	}

	void PreIteration(float TimeSinceStart, float LoopDuration) override
	{
		auto PunchObstacle = Cast<ADentistPunchObstacle>(Owner);

		const FVector PreviousLocation = PunchObstacle.MoveIntoPlayerShapeComp.WorldLocation;

		PunchObstacle.UpdateSimulationLocation(TimeSinceStart, LoopDuration, -1);

		const FVector NewLocation = PunchObstacle.MoveIntoPlayerShapeComp.WorldLocation;

		TraceForBalls(PreviousLocation, NewLocation);
	}

	private void TraceForBalls(FVector From, FVector To)
	{
		auto PunchObstacle = Cast<ADentistPunchObstacle>(Owner);

		if(!PunchObstacle.bIsExtending)
			return;

		if(From.Equals(To))
			return;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		TraceSettings.UseShape(PunchObstacle.MoveIntoPlayerShapeComp.Shape);
		TraceSettings.IgnoreActor(PunchObstacle);
		FHitResult Hit = TraceSettings.QueryTraceSingle(From, To);
		if(!Hit.bBlockingHit)
			return;

		ADentistLaunchedBall LaunchedBall = Cast<ADentistLaunchedBall>(Hit.Actor);
		if(LaunchedBall == nullptr)
			return;

		const FVector Delta = To - From;
		LaunchedBall.SphereComp.AddWorldOffset(Delta);

		if(HitBalls.Contains(LaunchedBall))
			return;
		
		FVector Impulse = FVector::UpVector * 1000;
		Impulse += Delta.VectorPlaneProject(FVector::UpVector).GetSafeNormal() * 1000;

		FVector Velocity = Delta / SimulationLoop.SimulationTimeStep;
		Impulse += Velocity;

		LaunchedBall.SimulationComp.PendingImpulse += Impulse;
		LaunchedBall.SimulationComp.TempIgnoredActors.Add(PunchObstacle);

		HitBalls.Add(LaunchedBall);
	}

	void ResetPostSimulation() override
	{
		auto PunchObstacle = Cast<ADentistPunchObstacle>(Owner);
		PunchObstacle.UpdateSimulationLocation(0, SimulationLoop.LoopDuration, -1);
	}

	void Visualize(UHazeScriptComponentVisualizer Visualizer, float TimeSinceStart, float LoopDuration) const override
	{
		auto PunchObstacle = Cast<ADentistPunchObstacle>(Owner);

		bool bIsExtending = false;
		int PunchLoopCount;
		float PunchLoopAlpha;
		const FVector RelativeLocation = PunchObstacle.GetRelativeLocationAtTime(
			TimeSinceStart,
			LoopDuration,
			bIsExtending,
			PunchLoopCount,
			PunchLoopAlpha
		);

		const FTransform PunchRootTransform = FTransform(PunchObstacle.PunchRoot.WorldRotation, PunchObstacle.PunchRoot.WorldTransform.TransformPositionNoScale(RelativeLocation));

		Visualizer.DrawWorldString(f"{PunchLoopAlpha=}", PunchRootTransform.Location);

		TArray<USceneComponent> AttachedComponents;
		PunchObstacle.PunchRoot.GetChildrenComponents(true, AttachedComponents);
		for(USceneComponent AttachedComponent : AttachedComponents)
		{
			UStaticMeshComponent StaticMeshComp = Cast<UStaticMeshComponent>(AttachedComponent);
			if(StaticMeshComp == nullptr)
				continue;
			
			FTransform RelativeTransform = StaticMeshComp.WorldTransform.GetRelativeTransform(PunchObstacle.PunchRoot.WorldTransform);

			FTransform AttachedTransform = RelativeTransform * PunchRootTransform;

			// Go through all children and visualize them as well
			UMaterialInterface Material = Editor::IsSelected(Owner) ? KineticActorVisualizer::GetSelectedMaterial() : KineticActorVisualizer::GetUnselectedMaterial();

			Visualizer.DrawMeshWithMaterial(
				StaticMeshComp.StaticMesh,
				Material,
				AttachedTransform.Location,
				AttachedTransform.Rotation,
				AttachedTransform.Scale3D
			);
		}
	}
#endif
};