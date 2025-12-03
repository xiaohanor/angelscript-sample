UCLASS(Abstract)
class UFeatureAnimInstanceCurrentSwim : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCurrentSwim Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCurrentSwimAnimData AnimData;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerSwimmingAnimData SwimmingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector BSValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMio = false;

	// Components
	UPlayerMovementComponent MoveComp;
	UPlayerSwimmingComponent SwimComponent;

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 10;
	const float HIP_PITCH_INTERPSPEED_STOP = 4;
	const float MaxRoll = 60;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwimComponent = UPlayerSwimmingComponent::GetOrCreate(Player);

		bIsMio = Player.IsMio();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCurrentSwim NewFeature = GetFeatureAsClass(ULocomotionFeatureCurrentSwim);
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
		SwimmingAnimData = SwimComponent.AnimData;
		
		float PitchTarget = 0;
		float YawTarget = 0;
		float RollTarget = 0;
		float InterpSpeed;

		FVector LocalVelocity = Player.GetActorLocalVelocity();
		PitchTarget = Math::Clamp(FRotator::MakeFromXZ(LocalVelocity.GetSafeNormal(), MoveComp.WorldUp).Pitch, HIP_PITCH_MIN, HIP_PITCH_MAX);
		YawTarget = Math::Clamp(FRotator::MakeFromXZ(LocalVelocity.GetSafeNormal(), MoveComp.WorldUp).Yaw, HIP_PITCH_MIN, HIP_PITCH_MAX);
		RollTarget = Math::GetMappedRangeValueClamped(FVector2D(HIP_PITCH_MIN, HIP_PITCH_MAX), FVector2D(-MaxRoll, MaxRoll), YawTarget);

		if(MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector)
		{
			InterpSpeed = HIP_PITCH_INTERPSPEED_SWIMMING;
		}
		else
		{
			InterpSpeed = HIP_PITCH_INTERPSPEED_STOP;
		}

		// Interpolate the rotation
		const float NewPitch = Math::FInterpTo(HipsRotation.Pitch, PitchTarget, DeltaTime, InterpSpeed);
		const float NewYaw = Math::FInterpTo(HipsRotation.Yaw, YawTarget, DeltaTime, InterpSpeed);
		const float NewRoll = Math::FInterpTo(HipsRotation.Roll, RollTarget, DeltaTime, InterpSpeed);

		HipsRotation.Pitch = NewPitch;
		HipsRotation.Yaw = NewYaw;
		HipsRotation.Roll = NewRoll;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
