UCLASS(Abstract)
class UFauxPhysicsComponentBase : USceneComponent
{
	UPROPERTY(Category = "Settings", EditAnywhere)
	bool bStartDisabled = false;

	// If set, the actor's time dilation is completely ignored by the faux physics
	UPROPERTY(Category = "Settings", EditAnywhere, AdvancedDisplay)
	bool bIgnoreActorTimeDilation = false;

	// When the faux physics component is disabled, stop all velocity immediately
	UPROPERTY(Category = "Settings", EditAnywhere, AdvancedDisplay)
	bool bStopVelocityWhenDisabled = true;

	// Sub-step settings
	// Maximum time per step. If a frame is longer than this time, it will be broken up into sub-steps
	// Setting to 0 will disable sub-stepping
	float MaxStepTime = 1.0 / 120.0;

	// Base functions
	void ResetPhysics() {}
	void ApplyForce(FVector Origin, FVector Force) {}
	void ApplyImpulse(FVector Origin, FVector Impulse) {}
	void ApplyMovement(FVector Origin, FVector Movement) { devError(f"ApplyMovement not implemented on {this}"); }

	TArray<FInstigator> DisableInstigators;

	private TArray<UFauxPhysicsComponentBase> DependentChildComponents;
	private TArray<FTransform> DependentChildRelativeTransforms;

	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PrePhysics;
	bool bIsSleeping = false;
	uint LastUpdateFrame = 0;

	UFUNCTION(BlueprintPure)
	bool IsEnabled()
	{
		return DisableInstigators.Num() == 0;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		AddPhysicsComponentToDebugger(this);
#endif

		if (bStartDisabled)
			AddDisabler(this);
		else if (CanSleep())
			Sleep();

		for (int i = 0, ChildCount = GetNumChildrenComponents(); i < ChildCount; ++i)
		{
			auto ChildPhysics = Cast<UFauxPhysicsComponentBase>(GetChildComponent(i));
			if (ChildPhysics != nullptr)
			{
				ChildPhysics.AddTickPrerequisiteComponent(this);
				DependentChildComponents.Add(ChildPhysics);
			}
		}
	}

	bool HasFauxPhysicsControl() const
	{
		return HasControl();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
#if EDITOR
		RemovePhysicsComponentFromDebugger(this);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float InOriginalDeltaTime)
	{
		UpdateFauxPhysics(InOriginalDeltaTime);
	}

	bool UpdateFauxPhysics(float InOriginalDeltaTime)
	{
		if (!IsEnabled())
			return false;

		if (LastUpdateFrame == GFrameNumber)
			return false;
		LastUpdateFrame = GFrameNumber;

		DependentChildRelativeTransforms.SetNum(DependentChildComponents.Num());
		for (int i = 0, ChildCount = DependentChildComponents.Num(); i < ChildCount; ++i)
		{
			if (IsValid(DependentChildComponents[i]))
			{
				DependentChildRelativeTransforms[i] = DependentChildComponents[i].RelativeTransform;
				SceneComponent::SetAbsoluteNoUpdateComponentToWorld(DependentChildComponents[i], true);
			}
		}

		float DeltaTime = InOriginalDeltaTime;
		if (bIgnoreActorTimeDilation)
			DeltaTime = Time::GlobalWorldDeltaSeconds;

		if (HasFauxPhysicsControl())
		{
			float RemainingSimulationTime = DeltaTime;
			while (RemainingSimulationTime > SMALL_NUMBER)
			{
				float StepTime = Math::Min(RemainingSimulationTime, MaxStepTime);

				PhysicsStep(StepTime);
				RemainingSimulationTime -= StepTime;
			}

			ControlUpdateSyncedPosition();
		}
		else
		{
			RemoteUpdateSyncedPosition();
		}

		ResetForces();

		if (PreventSleepUntilFrame <= GFrameNumber && CanSleep())
			Sleep();

		for (int i = 0, ChildCount = DependentChildComponents.Num(); i < ChildCount; ++i)
		{
			UFauxPhysicsComponentBase Child = DependentChildComponents[i];
			if (IsValid(Child))
			{
				FTransform PreviousChildToWorld = Child.GetWorldTransform();
				SceneComponent::SetAbsoluteResetRelative(Child, false, DependentChildRelativeTransforms[i]);
				FTransform StartingChildToWorld = Child.GetWorldTransform();

				Child.UpdateFauxPhysics(InOriginalDeltaTime);

				// If the parent moved, but the child didn't move, then we need to trigger an additional component update to put it in the right place
				if (!PreviousChildToWorld.Equals(StartingChildToWorld))
				{
					FTransform UpdatedChildToWorld = Child.GetWorldTransform();
					if (UpdatedChildToWorld.Equals(StartingChildToWorld))
						SceneComponent::UpdateComponentToWorld(Child);
				}
			}
		}

		return true;
	}

	bool CanSleep() const
	{
		return false;
	}

	bool IsSleeping() const
	{
		return bIsSleeping;
	}

	private uint64 OnMovedDelegateHandle = 0;
	private uint32 PreventSleepUntilFrame = 0;
	private FTransform SleepTransform;

	void Sleep()
	{
		if (!bIsSleeping)
		{
			OnMovedDelegateHandle = SceneComponent::BindOnSceneComponentMoved(this, FOnSceneComponentMoved(this, n"OnMovedWhileSleeping"));
			SleepTransform = GetWorldTransform();

			AddComponentTickBlocker(n"Sleeping");
			bIsSleeping = true;
		}
	}

	UFUNCTION()
	private void OnMovedWhileSleeping(USceneComponent MovedComponent, bool bIsTeleport)
	{
		if (!SleepTransform.Equals(GetWorldTransform()))
			Wake();
	}

	void Wake()
	{
		PreventSleepUntilFrame = GFrameNumber + 100;

		if (bIsSleeping)
		{
			RemoveComponentTickBlocker(n"Sleeping");
			bIsSleeping = false;

			SceneComponent::UnbindOnSceneComponentMoved(this, OnMovedDelegateHandle);
			OnMovedDelegateHandle = 0;
		}
	}

	protected void PhysicsStep(float DeltaTime)
	{
		devError(f"UFauxPhysicsComponentBase::PhysicsStep triggered on '{Name}'\nMake sure to implement PhysicsStep instead of Tick for your calculations! (And dont call Super)");
	}

	protected void ControlUpdateSyncedPosition()
	{
	}

	protected void RemoteUpdateSyncedPosition()
	{
	}

	void ResetForces() {}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		bool bWasEnabled = IsEnabled(); 

		DisableInstigators.Add(DisableInstigator);
		AddComponentTickBlocker(DisableInstigator);

		// If we're newly disabled, reset all the transient state
		if (bWasEnabled)
		{
			ResetForces();
			if (bStopVelocityWhenDisabled)
				ResetPhysics();
		}
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		bool bWasEnabled = IsEnabled(); 
		
		DisableInstigators.Remove(DisableInstigator);
		RemoveComponentTickBlocker(DisableInstigator);

		// If we're newly enabled, reset all the transient state
		if (!bWasEnabled)
		{
			ResetForces();
			if (bStopVelocityWhenDisabled)
				ResetPhysics();
		}
	}

	UFUNCTION()
	void RemoveAllDisablers(FInstigator DisableInstigator)
	{
		bool bWasEnabled = IsEnabled(); 

		for (auto Disabler : DisableInstigators)
			RemoveComponentTickBlocker(Disabler);
		DisableInstigators.Empty();

		// If we're newly enabled, reset all the transient state
		if (!bWasEnabled)
		{
			ResetForces();
			if (bStopVelocityWhenDisabled)
				ResetPhysics();
		}
	}

	UFUNCTION(BlueprintCallable)
	void ResetInternalState()
	{
		ResetPhysics();
	}

	void OverrideNetworkSyncRate(EHazeCrumbSyncRate SyncRate) {}
}