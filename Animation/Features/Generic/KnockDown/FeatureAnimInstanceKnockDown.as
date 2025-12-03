UCLASS(Abstract)
class UFeatureAnimInstanceKnockDown : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureKnockDown Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureKnockDownAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStandUp = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection Direction;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsForward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	UPlayerKnockdownComponent KnockdownComp;
	UHazePhysicalAnimationComponent PhysComp;
	UPlayerMovementComponent MoveComponent;

	bool bAllowAir;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr && HazeOwningActor.AttachParentActor != nullptr)
		{
			KnockdownComp = UPlayerKnockdownComponent::Get(HazeOwningActor.AttachParentActor);
			MoveComponent = UPlayerMovementComponent::Get(HazeOwningActor.AttachParentActor);
		}
		else
		{
			KnockdownComp = UPlayerKnockdownComponent::Get(HazeOwningActor);
			MoveComponent = UPlayerMovementComponent::Get(HazeOwningActor);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureKnockDown NewFeature = GetFeatureAsClass(ULocomotionFeatureKnockDown);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bAllowAir = AnimData.InAirMhFwd.Sequence != nullptr;

		if (Player != nullptr)
		{
			auto ActionModeComp = UPlayerActionModeComponent::GetOrCreate(Player);
			ActionModeComp.IncreaseActionScore(10);
		}

		Direction = KnockdownComp.AnimData.Direction;
		if (Feature.bUsePhysics && Direction != EHazeCardinalDirection::Forward)
		{
			PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
			PhysComp.ApplyProfileAsset(this, PhysProfile);
		}
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		// if (MoveComponent.IsInAir())
		// 	return 0.2;

		return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		bStandUp = KnockdownComp.AnimData.bStandUp;
		Direction = KnockdownComp.AnimData.Direction;

		bIsForward = Direction == EHazeCardinalDirection::Forward;

		bIsInAir = MoveComponent.IsInAir() && bAllowAir;
		bWantsToMove = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (PhysComp != nullptr)
		{
			if (LocomotionAnimationTag == n"Landing")
			{
				PhysComp.ClearProfileAsset(this, 0.06);
			}
			else
			{
				PhysComp.ClearProfileAsset(this);
			}
		}

		if (LocomotionAnimationTag == n"AirMovement")
			SetAnimFloatParam(n"AirMovementBlendTime", 0.6);
			
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"AirMovement")
			return true;

		if (TopLevelGraphRelevantStateName == n"StandUp" && LocomotionAnimationTag == n"AirMovement")
			return true;

		if (TopLevelGraphRelevantStateName == n"ToAirMovement" && LocomotionAnimationTag == n"Movement")
			return true;

		if (bStandUp && (TopLevelGraphRelevantStateName != n"StandUp" && TopLevelGraphRelevantStateName != n"ToAirMovement"))
			return false;

		if (TopLevelGraphRelevantStateName == n"StandUp")
		{
			// CanTransitionFrom is called before BlueprintUpdateAnimation
			const bool bWantsToMoveLocal = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();
			if (bWantsToMove != bWantsToMoveLocal)
				return TopLevelGraphRelevantAnimTimeFraction > 0.65; // moving changed, leave if we're almost done
		}

		return IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION()
	void AnimNotify_EnteredExit()
	{
		if (PhysComp != nullptr)
			PhysComp.ClearProfileAsset(this, 0.6);
	}
}
