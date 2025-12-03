UCLASS(Abstract)
class UFeatureAnimInstanceDragonSwordWeakPoint : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDragonSwordWeakPoint Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDragonSwordWeakPointAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DrawBackExplicitTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDrawBackFinished;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHoldSuccessMH;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerStoneBossQTEWeakpointType WeakpointType;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerStoneBossQTEFinalWeakpointStateInfo FinalWeakpointActiveStateInfo;

	UPlayerMovementComponent MoveComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::GetOrCreate(Player);

		MoveComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDragonSwordWeakPoint NewFeature = GetFeatureAsClass(ULocomotionFeatureDragonSwordWeakPoint);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		DrawBackExplicitTime = WeakpointComp.DrawBackAlpha * AnimData.Charge.Sequence.GetPlayLength();

		bDrawBackFinished = WeakpointComp.DrawBackAlpha > WeakpointComp.DrawBackAlphaThreshold;

		bPlayExit = LocomotionAnimationTag != Feature.Tag;

		WeakpointType = WeakpointComp.WeakpointType;

		if (WeakpointComp.Weakpoint != nullptr)
			FinalWeakpointActiveStateInfo = WeakpointComp.Weakpoint.StoneBossButtonMashComp.FinalWeakpointActiveStateInfo;

		bHoldSuccessMH = WeakpointComp.bHoldSuccessMH;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"SwordWindWalk")
			return true;

		if (Player.ActorVelocity.Size() > 100)
			return true;

		return LowestLevelGraphRelevantStateName == n"Exit" && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
