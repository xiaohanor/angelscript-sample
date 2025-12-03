event void FOnMeltdownScreenWalkJumpTrigger();
event void FOnMeltdownScreenWalkRangeTrigger();

struct FMeltdownResponseRayData
{
	bool bIsInRange = false;
	FVector TargetPoint;
	FVector PointOnRay;
	FVector PointOnTrigger;
}

class UMeltdownScreenWalkResponseComponent : UActorComponent
{
	AMeltdownScreenWalkManager Manager;
	
	UPROPERTY(EditAnywhere, Category = "Trigger")
	float TriggerMaxDepth = 10000.0;
	UPROPERTY(EditAnywhere, Category = "Trigger")
	FHazeShapeSettings TriggerShape = FHazeShapeSettings::MakeSphere(400.0);
	UPROPERTY(EditAnywhere, Category = "Trigger")
	float TriggerMaxSidewaysDistance = 0.0;
	UPROPERTY(EditAnywhere, Category = "Trigger", Meta = (UseComponentPicker, AllowedClasses = "/Script/Engine.SceneComponent"))
	FComponentReference TriggerPositionComponent;

	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bApplySuckToFauxPhysics = false;
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	float FauxPhysicsSuckForce = 500.0;
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bSuckSnapsToMovement = true;
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bSuckSnapMovesToPlayerPoint = true;
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bOnlySuckWhileStomping = true;
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bPermanentAttachFromStomp = false;
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bDisableWeightsWhileSucking = true;

	// Allow somping this to be triggered by moving onto it while holding stomp
	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bTriggerStompContinuously = false;

	UPROPERTY(EditAnywhere, Category = "Suck Trigger")
	FOnMeltdownScreenWalkRangeTrigger OnEnteredSuckRange;
	UPROPERTY(EditAnywhere, Category = "Suck Trigger")
	FOnMeltdownScreenWalkRangeTrigger OnExitedSuckRange;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	FOnMeltdownScreenWalkJumpTrigger OnStompedTrigger;
	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	FOnMeltdownScreenWalkJumpTrigger OnStompReleasedTrigger;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	FOnMeltdownScreenWalkJumpTrigger OnJumpTrigger;

	private bool bIsInSuckRange = false;
	private bool bIsSuckSnapped = false;
	private bool bIsStomped = false;
	private bool bPlayerStompIsActive = false;
	private FVector LastSuckPlayerLocation;

	private TArray<UFauxPhysicsWeightComponent> Weights;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Manager = AMeltdownScreenWalkManager::Get();
		Manager.ResponseComponents.Add(this);

		Owner.RootComponent.GetChildrenComponentsByClass(UFauxPhysicsWeightComponent, true, Weights);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Manager.ResponseComponents.RemoveSingleSwap(this);
	}

	bool HasStompControl() const
	{
		return Game::Zoe.HasControl();
	}

	FMeltdownResponseRayData GetCurrentRayData() const
	{
		FMeltdownResponseRayData RayData;

		RayData.TargetPoint = Owner.ActorLocation;

		FTransform TriggerTransform = Owner.ActorTransform;
		auto PositionComponent = Cast<USceneComponent>(TriggerPositionComponent.GetComponent(Owner));
		if (PositionComponent != nullptr)
		{
			RayData.TargetPoint = PositionComponent.WorldLocation;
			TriggerTransform = PositionComponent.WorldTransform;
		}

		RayData.PointOnTrigger = TriggerShape.GetClosestPointToLine(
			TriggerTransform, Manager.ScreenWalkRayOrigin, Manager.ScreenWalkRayDirection,
		);

		RayData.PointOnRay = Math::ClosestPointOnInfiniteLine(
			Manager.ScreenWalkRayOrigin,
			Manager.ScreenWalkRayOrigin + Manager.ScreenWalkRayDirection,
			RayData.PointOnTrigger,
		);

		FVector Delta = RayData.PointOnRay - Manager.ScreenWalkRayOrigin;
		float Depth = Delta.DotProduct(Manager.ScreenWalkRayDirection);

		float Distance = RayData.PointOnRay.Distance(RayData.PointOnTrigger);
		RayData.bIsInRange = Depth <= TriggerMaxDepth && Distance <= TriggerMaxSidewaysDistance + 1.0;

		return RayData;
	}

	void OnPlayerLandedJump()
	{
		// FMeltdownResponseRayData RayData = GetCurrentRayData();
		// if (RayData.bIsInRange)
		// 	OnJumpTrigger.Broadcast();
	}

	void OnPlayerStartedStomp()
	{
		if (!HasStompControl())
			return;

		FMeltdownResponseRayData RayData = GetCurrentRayData();
		if (RayData.bIsInRange && !bIsStomped)
		{
			bIsStomped = true;
			CrumbStompTrigger();
		}

		bPlayerStompIsActive = true;
	}

	void OnPlayerEndedStomp()
	{
		if (!HasStompControl())
			return;

		if (bIsStomped)
		{
			bIsStomped = false;
			CrumbStompReleased();
		}

		bPlayerStompIsActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasStompControl())
			return;

		if ((bApplySuckToFauxPhysics || OnEnteredSuckRange.IsBound() || OnExitedSuckRange.IsBound() || bTriggerStompContinuously) && Manager.bScreenWalkRayActive)
		{
			FMeltdownResponseRayData RayData = GetCurrentRayData();
			if (RayData.bIsInRange || bIsSuckSnapped)
			{
				if (bApplySuckToFauxPhysics && (!bOnlySuckWhileStomping || bIsStomped || (bPermanentAttachFromStomp && bIsSuckSnapped)))
				{
					if (bSuckSnapsToMovement)
					{
						if (!bIsSuckSnapped)
						{
							LastSuckPlayerLocation = RayData.PointOnRay;
							bIsSuckSnapped = true;

							if (bDisableWeightsWhileSucking)
							{
								for (auto Weight : Weights)
									Weight.AddDisabler(this);
							}
						}

						FVector Movement = RayData.PointOnRay - LastSuckPlayerLocation;
						if (bSuckSnapMovesToPlayerPoint)
						{
							FVector PrevOffset = RayData.PointOnRay - RayData.TargetPoint;
							FVector NewOffset = PrevOffset * Math::Pow(0.05, DeltaSeconds);

							Movement -= (NewOffset - PrevOffset);
						}

						FauxPhysics::ApplyFauxMovementToActorAt(Owner, RayData.TargetPoint, Movement);
						LastSuckPlayerLocation = RayData.PointOnRay;

						FMeltdownResponseRayData NewRayData = GetCurrentRayData();
						if (!NewRayData.bIsInRange)
						{
							bIsSuckSnapped = false;
							if (bDisableWeightsWhileSucking)
							{
								for (auto Weight : Weights)
									Weight.RemoveDisabler(this);
							}
						}
					}
					else
					{
						FVector ForceDirection = (RayData.PointOnRay - RayData.TargetPoint).GetSafeNormal();
						FauxPhysics::ApplyFauxForceToActorAt(Owner, RayData.TargetPoint, ForceDirection * FauxPhysicsSuckForce);
					}

					// Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ForceDirection * 500.0);
				}
				else if (bIsSuckSnapped)
				{
					bIsSuckSnapped = false;
					LastSuckPlayerLocation = FVector::ZeroVector;

					if (bDisableWeightsWhileSucking)
					{
						for (auto Weight : Weights)
							Weight.RemoveDisabler(this);
					}
				}

				if (!bIsInSuckRange)
				{
					CrumbEnteredSuckRange();
					bIsInSuckRange = true;
				}

				if (!bIsStomped && bTriggerStompContinuously && bPlayerStompIsActive)
				{
					bIsStomped = true;
					CrumbStompTrigger();
				}
			}
			else
			{
				if (bIsInSuckRange)
				{
					CrumbExitedSuckRange();
					bIsInSuckRange = false;
					LastSuckPlayerLocation = FVector::ZeroVector;
				}

				if (bIsStomped)
				{
					bIsStomped = false;
					CrumbStompReleased();
				}
			}
		}
		else
		{
			if (bIsInSuckRange)
			{
				CrumbExitedSuckRange();
				bIsInSuckRange = false;
				LastSuckPlayerLocation = FVector::ZeroVector;
			}

			if (bIsSuckSnapped)
			{
				bIsSuckSnapped = false;

				if (bDisableWeightsWhileSucking)
				{
					for (auto Weight : Weights)
						Weight.RemoveDisabler(this);
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStompTrigger()
	{
		OnStompedTrigger.Broadcast();
		OnJumpTrigger.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStompReleased()
	{
		OnStompReleasedTrigger.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEnteredSuckRange()
	{
		OnEnteredSuckRange.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExitedSuckRange()
	{
		OnExitedSuckRange.Broadcast();
	}

};

#if EDITOR
class UMeltdownScreenWalkResponseVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMeltdownScreenWalkResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ResponseComp = Cast<UMeltdownScreenWalkResponseComponent>(Component);

		FTransform TriggerTransform = ResponseComp.Owner.ActorTransform;
		auto PositionComponent = Cast<USceneComponent>(ResponseComp.TriggerPositionComponent.GetComponent(ResponseComp.Owner));
		if (PositionComponent != nullptr)
			TriggerTransform = PositionComponent.WorldTransform;

		DrawWireShapeSettings(
			ResponseComp.TriggerShape,
			TriggerTransform.Location, TriggerTransform.Rotation, FLinearColor::Yellow, 5.0
		);
	}
}
#endif