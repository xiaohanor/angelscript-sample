UCLASS(Abstract)
class UFeatureAnimInstanceSanctuaryFlight : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSanctuaryFlight Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSanctuaryFlightAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	USanctuaryFlightAnimationComponent FlightComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FVector2D MoveBlendValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FVector2D SetBlendValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D InputValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	FVector2D RotationSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AccelerationVelocityDot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AccDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D DeAccDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DashDirectionTest;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bIsDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCanSetDeAcc;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D SetDeAccDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingToDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	EHazeSanctuaryFlightDashAnimationType DashDirection;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSanctuaryFlight NewFeature = GetFeatureAsClass(ULocomotionFeatureSanctuaryFlight);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		FlightComp = USanctuaryFlightAnimationComponent::Get(Player);

		bIsDashing = false;

		bCanSetDeAcc = false;


	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Custom Logic here :

		InputValue = FlightComp.WantedDirection;

		MoveBlendValue = FlightComp.MovementBlendSpaceValue;


		

		AccelerationVelocityDot = FlightComp.BlendSpaceAcceleration.DotProduct(MoveBlendValue);

		AccDirection.X = (InputValue.X * AccelerationVelocityDot) + MoveBlendValue.X;
		AccDirection.Y = (InputValue.Y * AccelerationVelocityDot) + MoveBlendValue.Y;

		DeAccDirection = AccDirection;


		if (MoveBlendValue.X <= -0.5)
			DashDirection = EHazeSanctuaryFlightDashAnimationType::Left;
		else if (MoveBlendValue.X >= 0.5)
			DashDirection = EHazeSanctuaryFlightDashAnimationType::Right;
		else if (MoveBlendValue.Y >= 0.5)
			DashDirection = EHazeSanctuaryFlightDashAnimationType::Upwards;
		else if (MoveBlendValue.Y <= -0.5) 
			DashDirection = EHazeSanctuaryFlightDashAnimationType::Downwards;

		if (CheckValueChangedAndSetBool(bIsRequestingToDashing, (MoveBlendValue.Size() > 0.9), EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			
			//FRotator Test = Math::RadiansToDegrees(Math::Atan2(FlightComp.WantedDirection.X, FlightComp.WantedDirection.Y));
			
			DashDirectionTest = Math::RadiansToDegrees(Math::Atan2(FlightComp.WantedDirection.X, FlightComp.WantedDirection.Y));
			
			if (DashDirectionTest < 0)
				DashDirectionTest = (360 + DashDirectionTest);	
		}


		if (bIsDashing == true)
		{
			SetBlendValue = MoveBlendValue;
		}

		if (bCanSetDeAcc == true)
			SetDeAccDirection = DeAccDirection;

		
		RotationSpeed = (MoveBlendValue * 20);

		HipsRotation.Roll += RotationSpeed.X;
		HipsRotation.Yaw -= RotationSpeed.Y;

		if (TopLevelGraphRelevantStateName != n"DashStop")
		{
			HipsRotation.Roll = 0;
			HipsRotation.Yaw = 0;
		}

#if EDITOR
		//OwningComponent.bHazeEditorOnlyDebugBool = true;		
		if (OwningComponent.bHazeEditorOnlyDebugBool)
		{
			//PrintToScreenScaled("MoveBlendValue: " + MoveBlendValue.Size(), 0.0);
			//PrintToScreenScaled("SetBlendValue: " + SetBlendValue, 0.0);
			//PrintToScreenScaled("TargetValues: " + FlightComp.BlendSpaceHorizontal.Get() + ", " + FlightComp.BlendSpaceVertical.Get(), 0.0);

			//Print("DashDirection: " + DashDirectionTest, 0.0);
			
			//PrintToScreenScaled("Input: " + InputValue, 0.0);
			//PrintToScreenScaled("MoveBlendValue: " + MoveBlendValue, 0.0, Scale = 3.0);
			PrintToScreenScaled("Acc: " + AccelerationVelocityDot, 0.0, Scale = 3.0);
			PrintToScreenScaled("DeAcceleration: " + DeAccDirection, 0.0, Scale = 3.0);
			PrintToScreenScaled("Acceleration: " + AccDirection, 0.0, Scale = 3.0);
			Print("SetDeAccDirection: " + SetDeAccDirection, 0.0);
		}
#endif
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
    UFUNCTION()
    void AnimNotify_LeftDash()
    {
		bIsDashing = false;
    }

	UFUNCTION()
    void AnimNotify_EnterDash()
    {
		bIsDashing = true;
    }

    UFUNCTION()
    void AnimNotify_EnterFlight()
    {
        bCanSetDeAcc = true;
    }

	UFUNCTION()
    void AnimNotify_StartFlight()
    {
        bCanSetDeAcc = true;
    }

	UFUNCTION()
    void AnimNotify_EnterStopFlight()
    {
        bCanSetDeAcc = false;
    }

	UFUNCTION()
    void AnimNotify_LeftStopFlight()
    {
        bCanSetDeAcc = true;
    }

}
