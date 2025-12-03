UCLASS(Abstract)
class UFeatureAnimInstanceSimpleDragonLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleDragonLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleDragonLandingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput TraceInputData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableFootIK;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UAnimFootTraceComponent FootTraceComp;
	UHazeMovementComponent MoveComp;

	// AHazeActor Dragon;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto Dragon = Cast<ATeenDragon>(HazeOwningActor);
		bIsPlayer = Dragon == nullptr;
		if (bIsPlayer)
		{
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		}
		else
		{
			MoveComp = UHazeMovementComponent::Get(Dragon.DragonComponent.Owner);
			FootTraceComp = UAnimFootTraceComponent::Get(HazeOwningActor);
			FootTraceComp.SetMovementComp(MoveComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleDragonLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleDragonLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(MoveComp.Owner);
		SlopeAlignComp.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);

		if (FootTraceComp != nullptr)
			FootTraceComp.InitializeTraceDataVariable(TraceInputData);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.03;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;

		if (!bIsPlayer)
			SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.4);

		// Foot IK
		bEnableFootIK = FootTraceComp != nullptr && FootTraceComp.AreRequirementsMet();
		if (bEnableFootIK)
			FootTraceComp.TraceFeet(TraceInputData);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"DragonRiding")
			return true;

		if (TopLevelGraphRelevantStateName == n"ExitToMovement" && !bWantsToMove)
			return true;

		if (TopLevelGraphRelevantStateName == n"ExitToMm" && bWantsToMove)
			return true;

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Movement" || LocomotionAnimationTag == n"DragonRiding")
		{
			if (TopLevelGraphRelevantStateName == n"ExitToMovement" && bWantsToMove)
			{
				SetAnimBoolParam(n"SkipMovementStart", true);
				SetAnimBlendTimeToMovement(HazeOwningActor, 0);
			}
		}
	}
}
