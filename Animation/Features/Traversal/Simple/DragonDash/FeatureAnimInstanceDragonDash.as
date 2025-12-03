UCLASS(Abstract)
class UFeatureAnimInstanceDragonDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDragonDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDragonDashAnimData AnimData;

	// Add Custom Variables Here
	UHazeAnimSlopeAlignComponent AnimSlopeAlignComponent;
	UPlayerTeenDragonComponent DragonComp;
	UAnimFootTraceComponent FootTraceComp;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter RidingPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput TraceInputData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableFootIK;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprinting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	// Speed
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		bIsPlayer = HazeOwningActor.IsA(AHazePlayerCharacter);
		if (bIsPlayer)
		{
			RidingPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor);
			DragonComp = UPlayerTeenDragonComponent::Get(RidingPlayer);
		}
		else
		{
			auto DragonOwner = Cast<ATeenDragon>(HazeOwningActor);
			DragonComp = DragonOwner.DragonComponent;
			RidingPlayer = Cast<AHazePlayerCharacter>(DragonComp.Owner);
		}

		MoveComp = UHazeMovementComponent::Get(RidingPlayer);

		if (!bIsPlayer)
		{
			FootTraceComp = UAnimFootTraceComponent::Get(HazeOwningActor);
			FootTraceComp.SetMovementComp(MoveComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDragonDash NewFeature = GetFeatureAsClass(ULocomotionFeatureDragonDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// auto TeenDragon = Cast<ATeenDragon>(HazeOwningActor);

		AnimSlopeAlignComponent = UHazeAnimSlopeAlignComponent::GetOrCreate(MoveComp.Owner);
		AnimSlopeAlignComponent.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);

		if (FootTraceComp != nullptr)
			FootTraceComp.InitializeTraceDataVariable(TraceInputData);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (MoveComp == nullptr)
			return;

		// TODO (ns): Is speed needed here? otherwise remove it
		Speed = HazeOwningActor.ActorVelocity.Size();
		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}

		AnimSlopeAlignComponent.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.2);
		bIsSprinting = DragonComp.bIsSprinting;

		bEnableFootIK = FootTraceComp != nullptr && FootTraceComp.AreRequirementsMet() && TopLevelGraphRelevantStateName == n"Mh";
		if (bEnableFootIK)
			FootTraceComp.TraceFeet(TraceInputData);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// If any tag that's not movement is requested, leave this abp.

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"DragonRiding")
			return true;

		// Finish playing the Mh animation before leaving
		return IsTopLevelGraphRelevantAnimFinished() && (TopLevelGraphRelevantStateName == n"Mh" || TopLevelGraphRelevantStateName == n"ToMovement" || TopLevelGraphRelevantStateName == n"Sprint");
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag == n"Movement" || LocomotionAnimationTag == n"DragonRiding")
			SetAnimBoolParam(n"SkipMovementStart", true);
	}
}
