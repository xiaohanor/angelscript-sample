UCLASS(Abstract)
class USkylineAllyElevatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorReverse() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedTop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedBottom() {}
}

class ASkylineAllyElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent ElevatorPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	FHazeTimeLike ElevatorMovementTimeLike;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalLocation;
#endif

	bool bActivated = false;

	UPROPERTY(Category = Settings)
	float UpForce = 1000.0;

	UPROPERTY(Category = Settings)
	float DownForce = -1000.0;

	UPROPERTY(EditInstanceOnly)
	ASkylinePowerPlugSpool Spool;

	float ConstrainMaxZ;
	bool bIsActive;

	ASkylinePowerPlugSocket PoweringSocket;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		ElevatorMovementTimeLike.BindUpdate(this, n"ElevatorMovementTimeLikeUpdate");
		ElevatorMovementTimeLike.BindFinished(this, n"ElevatorMovementTimeLikeFinished");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
		ConstrainMaxZ = TranslateComp.MaxZ;

		DevTogglesSkyline::AllyElevatorRaise.MakeVisible();
		DevTogglesSkyline::AllyElevatorRaise.BindOnChanged(this, n"OnToggleBoolChanged");
		if (DevTogglesSkyline::AllyElevatorRaise.IsEnabled())
			ActivateElevator();
	}

	UFUNCTION()
	private void OnToggleBoolChanged(bool bNewState)
	{
		if (bNewState)
			ActivateElevator();
		else
			DeactivateElevator();
	}

	UFUNCTION()
	private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max && bIsActive)
		{
			USkylineAllyElevatorEventHandler::Trigger_OnReachedTop(this);
		}

		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
		{
			USkylineAllyElevatorEventHandler::Trigger_OnReachedBottom(this);
		}
	}

	UFUNCTION()
	private void ElevatorMovementTimeLikeFinished()
	{
	}

	UFUNCTION()
	private void ElevatorMovementTimeLikeUpdate(float CurrentValue)
	{
		ForceComp.Force = Math::Lerp(FVector::UpVector * DownForce, FVector::UpVector * UpForce, CurrentValue);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		auto CallingSocket = Cast<ASkylinePowerPlugSocket>(Caller);

		if (IsValid(CallingSocket))
		{
			PoweringSocket = CallingSocket;
			ActivateElevator();		
		}
		else
			PrintToScreenScaled("Elevator has invalid caller", 3.0);
	}

	private void ActivateElevator()
	{
		bIsActive = true;

		TranslateComp.MaxZ = ConstrainMaxZ;

		ElevatorMovementTimeLike.SetPlayRate(2.0);
		ElevatorMovementTimeLike.Play();

		BP_Activated();

		USkylineAllyElevatorEventHandler::Trigger_OnElevatorStarted(this);
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		DeactivateElevator();
	}

	private void DeactivateElevator()
	{
		TranslateComp.MinZ = 0.0;
		TranslateComp.MaxZ = TranslateComp.GetCurrentAlphaBetweenConstraints().Z * ConstrainMaxZ;

		bIsActive = false;

		ElevatorMovementTimeLike.SetPlayRate(0.5);
		ElevatorMovementTimeLike.Reverse();

		BP_Deactivated();

		USkylineAllyElevatorEventHandler::Trigger_OnElevatorReverse(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (PoweringSocket != nullptr) // if we're using debug toggle bool we don't have a socket
		{
			bool bStretchedOut = PoweringSocket.GetDistanceTo(Spool) > Spool.CableLength * 1.05;
			bool bSocketIsBelow = PoweringSocket.ActorLocation.Z < ElevatorPivot.WorldLocation.Z;
			if (bSocketIsBelow && bStretchedOut && HasControl() && bIsActive)
				NetForceUnplug();
		}

		// Debug::DrawDebugString(ElevatorPivot.WorldLocation + ActorForwardVector * 600.0, "Active: " + bIsActive);
	}

	UFUNCTION(NetFunction)
	private void NetForceUnplug()
	{
		PoweringSocket.ForceUnplug();
		// PrintToScreenScaled("Forced Unplug", 3.0);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activated()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivated()
	{
	}
};