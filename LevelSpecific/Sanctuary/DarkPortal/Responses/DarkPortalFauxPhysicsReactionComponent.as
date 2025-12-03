enum EDarkPortalFauxPhysicsAccelerationMode
{
	AccelerationSpeed,
	Duration,
}

struct FDarkPortalFauxPhysicsAcceleratingData
{
	UFauxPhysicsTranslateComponent TranslateComp;
	float InitialDistance;
}

class UDarkPortalFauxPhysicsReactionComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	/**
	 * If set, when grabbed we don't apply a force to the faux physics, but
	 * attempt to accelerate it to the dark portal's location instead.
	 */
	UPROPERTY(EditAnywhere, Category = "Dark Portal")
	bool bApplyAsAccelerateToPoint = false;

	/**
	 * What method of acceleration to use for the portal acceleration.
	 */
	UPROPERTY(EditAnywhere, Category = "Dark Portal", Meta = (EditCondition = "bApplyAsAccelerateToPoint", EditConditionHides))
	EDarkPortalFauxPhysicsAccelerationMode AccelerationMode = EDarkPortalFauxPhysicsAccelerationMode::AccelerationSpeed;

	/**
	 * When accelerating to a point, the speed at which we accelerate.
	 */
	UPROPERTY(EditAnywhere, Category = "Dark Portal", Meta = (EditCondition = "bApplyAsAccelerateToPoint && AccelerationMode == EDarkPortalFauxPhysicsAccelerationMode::AccelerationSpeed", EditConditionHides))
	float AccelerationSpeed = 250.0;

	/**
	 * When accelerating to a point, the duration over which we accelerate.
	 */
	UPROPERTY(EditAnywhere, Category = "Dark Portal", Meta = (EditCondition = "bApplyAsAccelerateToPoint && AccelerationMode == EDarkPortalFauxPhysicsAccelerationMode::Duration", EditConditionHides))
	float AccelerationDuration = 8.0;

	/**
	 * When accelerating to a point, apply this minimum distance towards the dark portal.
	 */
	UPROPERTY(EditAnywhere, Category = "Dark Portal", Meta = (EditCondition = "bApplyAsAccelerateToPoint", EditConditionHides))
	float AccelerateToPointMinimumDistance = 0.0;

	private UDarkPortalResponseComponent ResponseComponent;

	private TArray<FDarkPortalFauxPhysicsAcceleratingData> AcceleratingComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComponent = UDarkPortalResponseComponent::GetOrCreate(Owner);
		ResponseComponent.OnAttached.AddUFunction(this, n"HandleAttached");
		ResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComponent.OnPushed.AddUFunction(this, n"HandlePushed");
	}

	private FDarkPortalFauxPhysicsAcceleratingData& GetOrCreateAcceleratingData(UFauxPhysicsTranslateComponent TranslateComp, FVector TargetLocation)
	{
		for (int i = 0, Count = AcceleratingComponents.Num(); i < Count; ++i)
		{
			if (AcceleratingComponents[i].TranslateComp == TranslateComp)
				return AcceleratingComponents[i];
		}

		FDarkPortalFauxPhysicsAcceleratingData NewData;
		NewData.TranslateComp = TranslateComp;
		NewData.InitialDistance = TranslateComp.WorldLocation.Distance(TargetLocation);
		TranslateComp.AddDisabler(this);
		AcceleratingComponents.Add(NewData);

		return AcceleratingComponents.Last();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ResponseComponent.Grabs.Num() == 0 && 
			ResponseComponent.Attaches.Num() == 0)
		{
			SetComponentTickEnabled(false);

			for (auto Data : AcceleratingComponents)
				Data.TranslateComp.RemoveDisabler(this);
			AcceleratingComponents.Reset();
			return;
		}

		if (bApplyAsAccelerateToPoint)
		{
			for (auto& Grab : ResponseComponent.Grabs)
			{
				// Find the translate component we're attached to
				UFauxPhysicsTranslateComponent TranslateComp;

				USceneComponent Component = Grab.TargetComponent;
				while (Component != nullptr)
				{
					auto FoundComp = Cast<UFauxPhysicsTranslateComponent>(Component);
					if (FoundComp != nullptr)
					{
						TranslateComp = FoundComp;
						break;
					}

					Component = Component.AttachParent;
				}


				if (TranslateComp != nullptr)
				{
					FVector TargetPoint = Grab.GrabTargetLocation;
					if (AccelerateToPointMinimumDistance != 0.0)
					{
						FVector DirectionFromTarget = (TranslateComp.WorldLocation - TargetPoint).GetSafeNormal();
						TargetPoint += DirectionFromTarget * AccelerateToPointMinimumDistance;
					}

					FDarkPortalFauxPhysicsAcceleratingData& AcceleratingData = GetOrCreateAcceleratingData(TranslateComp, TargetPoint);

					float CalculatedAccelerationDuration = 0;
					if (AccelerationMode == EDarkPortalFauxPhysicsAccelerationMode::Duration)
					{
						CalculatedAccelerationDuration = AccelerationDuration;
					}
					else if (AccelerationMode == EDarkPortalFauxPhysicsAccelerationMode::AccelerationSpeed)
					{
						CalculatedAccelerationDuration = 2.0 * (AcceleratingData.InitialDistance / AccelerationSpeed);
					}

					FHazeAcceleratedVector Vector;
					Vector.SnapTo(TranslateComp.WorldLocation, TranslateComp.GetVelocity());
					Vector.AccelerateTo(TargetPoint, CalculatedAccelerationDuration, DeltaTime);

					FVector NewLocation = TranslateComp.GetWorldLocationAfterConstraints(Vector.Value);
					if (NewLocation != TranslateComp.WorldLocation)
					{
						TranslateComp.SetVelocity((NewLocation - TranslateComp.WorldLocation) / DeltaTime);
						TranslateComp.WorldLocation = NewLocation;
					}
				}
			}
		}
		else
		{
			for (auto& Grab : ResponseComponent.Grabs)
			{
				auto AffectedComponent = DarkPortal::GetParentForceAnchor(Grab.TargetComponent);

				FauxPhysics::ApplyFauxForceToParentsAt(AffectedComponent, 
					AffectedComponent.WorldLocation,
					Grab.ConsumeForce());
			}

			for (auto& Attach : ResponseComponent.Attaches)
			{
				FauxPhysics::ApplyFauxForceToParentsAt(Attach.AttachComponent, 
					ResponseComponent.GetOriginLocationForPortal(Attach.Portal),
					Attach.ConsumeForce());
			}
		}
	}
	
	UFUNCTION()
	private void HandleAttached(ADarkPortalActor Portal,
		USceneComponent AttachComponent)
	{
		if (ResponseComponent.Attaches.Num() != 0)
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal,
		UDarkPortalTargetComponent TargetComponent)
	{
		if (ResponseComponent.Grabs.Num() != 0)
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void HandlePushed(ADarkPortalActor Portal,
		USceneComponent PushedComponent,
		FVector WorldLocation,
		FVector Impulse)
	{
		if (Impulse.IsNearlyZero())
			return;
		
		TArray<UFauxPhysicsComponentBase> Components;
		FauxPhysics::CollectPhysicsParents(Components, PushedComponent);

		for (auto PhysicsComp : Components)
		{
			PhysicsComp.ResetForces();
			PhysicsComp.ResetPhysics();
			PhysicsComp.ApplyImpulse(WorldLocation, Impulse);
		}
	}
}