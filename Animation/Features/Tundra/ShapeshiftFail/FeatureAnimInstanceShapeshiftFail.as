enum ETundraShapeshiftFailAnimStates
{
	Other,
	PoleClimb,
	Perch
}

UCLASS(Abstract)
class UFeatureAnimInstanceShapeshiftFail : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureShapeshiftFail Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureShapeshiftFailAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ETundraShapeshiftFailAnimStates RequestedState;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	UHazeBoneFilterAsset BoneFilterNull;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	UHazeBoneFilterAsset BoneFilterFullBodyEvalBase;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootScale;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	const float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShapeshiftBigger;

	FVector RootScaleTarget;
	float Speed;
	float RotationSpeed;

	UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		const bool bIsPlayer = Player != nullptr;
		const auto PlayerRef = bIsPlayer ? Player : Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);

		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(PlayerRef);
		MovementComponent = UPlayerMovementComponent::Get(PlayerRef);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureShapeshiftFail NewFeature = GetFeatureAsClass(ULocomotionFeatureShapeshiftFail);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (LocomotionAnimationTag == n"PoleClimb")
			RequestedState = ETundraShapeshiftFailAnimStates::PoleClimb;
		else if (LocomotionAnimationTag == n"Perch")
			RequestedState = ETundraShapeshiftFailAnimStates::Perch;
		else
			RequestedState = ETundraShapeshiftFailAnimStates::Other;

		bShapeshiftBigger = GetAnimIntParam(n"MorphDir", true) > 0;

		RootScale = FVector::OneVector;
		RootScaleTarget = FVector::OneVector * (bShapeshiftBigger ? 1.3 : 0.7);
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		if (RequestedState == ETundraShapeshiftFailAnimStates::Other)
			return BoneFilterNull;

		if (RequestedState == ETundraShapeshiftFailAnimStates::Perch)
			return BoneFilterFullBodyEvalBase;

		return Feature.DefaultOverrideBoneFilter;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = Player.ActorVelocity.Size();
		RotationSpeed = Math::Abs(MovementComponent.GetMovementYawVelocity(true));


		float Time = TopLevelGraphRelevantAnimTimeFraction;

		const float TopLevelAnimLenght = TopLevelGraphRelevantAnimTime + TopLevelGraphRelevantAnimTimeRemaining;
		if (TopLevelAnimLenght > 0.5)
		{
			Time = Math::Clamp(TopLevelGraphRelevantAnimTime / 0.5, 0.0, 1.0);
		}

		RootScale = Math::Lerp(FVector::OneVector, RootScaleTarget, Time);
		if (Time > 0.5)
			RootScale = Math::Lerp(RootScaleTarget, FVector::OneVector, Time);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName == n"Null")
			return true;

		if (RequestedState == ETundraShapeshiftFailAnimStates::Perch)
		{
			if ((RotationSpeed > 20 || Speed > 50) && TopLevelGraphRelevantAnimTime > 0.1)
				return true;
		}

		return IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeToNullFeature() const
	{
		if (RequestedState == ETundraShapeshiftFailAnimStates::Perch)
		{
			if (Speed > 50)
				return 0.2;
			return 0.5;
		}

		return 0.2;
	}
}
