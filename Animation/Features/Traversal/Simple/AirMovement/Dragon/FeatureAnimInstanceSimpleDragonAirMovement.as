UCLASS(Abstract)
class UFeatureAnimInstanceSimpleDragonAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleDragonAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleDragonAirMovementAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UHazeMovementComponent MoveComp;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;

	//AHazeActor Dragon;
	FQuat CachedActorQuat;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleDragonAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleDragonAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		auto Dragon = Cast<ATeenDragon>(HazeOwningActor);
		bIsPlayer = Dragon == nullptr;
		if (bIsPlayer)
		{
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		}
		else
		{
			MoveComp = UHazeMovementComponent::Get(Dragon.DragonComponent.Owner);
		}

		SlopeAlignComp = UHazeAnimSlopeAlignComponent::Get(MoveComp.Owner);
		SlopeAlignComp.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);

		CachedActorQuat = HazeOwningActor.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParam(n"AirMovementBlendTime", true, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendspaceValues.Y = HazeOwningActor.GetActorLocalVelocity().X;
		BlendspaceValues.X = CalculateAnimationBankingValue(HazeOwningActor, CachedActorQuat, DeltaTime, Feature.MaxTurnSpeed);

		if (!bIsPlayer)
		{
			SlopeOffset = Math::VInterpTo(SlopeOffset, FVector::ZeroVector, DeltaTime, 3);
			SlopeRotation = Math::RInterpTo(SlopeRotation, FRotator::ZeroRotator, DeltaTime, 3);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
