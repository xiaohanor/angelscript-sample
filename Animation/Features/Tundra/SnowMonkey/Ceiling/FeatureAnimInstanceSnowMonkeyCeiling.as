UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyCeiling : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyCeiling Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyCeilingAnimData AnimData;

	UPROPERTY(BlueprintReadOnly)
	bool bIsMoving = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSwitchHands;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReach;
	
	UHazeMovementComponent MoveComp;

	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyCeiling NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyCeiling);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);

		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(HazeOwningActor.AttachParentActor);

		ClearAnimBoolParam (n"SwitchHands");
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if(MoveComp == nullptr)
			return;

		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		if(SnowMonkeyComp.bIsInCeilingCoyoteSuckup || SnowMonkeyComp.bIsInCeilingSuckup)
		{
			HorizontalVelocity = SnowMonkeyComp.SuckUpVelocity.VectorPlaneProject(FVector::UpVector);
		}

		const float Size = 15.0;
		if(SnowMonkeyComp.CurrentCeilingComponent == nullptr && HorizontalVelocity.IsNearlyZero(Size))
			HorizontalVelocity = SnowMonkeyComp.Player.ActorForwardVector * Size;

		bIsMoving = !HorizontalVelocity.IsNearlyZero();

		Speed = HorizontalVelocity.Size();
		Print("Speed: " + Speed, 0.f);

		bSwitchHands = GetAnimBoolParam (n"SwitchHands", bConsume = false, bDefaultValue =  false);

		bReach = SnowMonkeyComp.bCeilingMovementWasConstrained == true;
		

	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		if(SnowMonkeyComp.bIsInCeilingCoyoteSuckup || SnowMonkeyComp.bIsInCeilingSuckup)
			return float32(SnowMonkeyComp.SuckupDuration);

		return 0.2;
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
