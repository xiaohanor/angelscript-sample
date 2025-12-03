UCLASS(Abstract)
class UFeatureAnimInstanceIceBow : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(BlueprintHidden, NotEditable)
	ULocomotionFeatureIceBow Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FLocomotionFeatureIceBowAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UIceBowPlayerComponent PlayerComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool Shoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AimAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ShootAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Charge;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIceAim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir;

	UPlayerMovementComponent MoveComponent; 

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureIceBow NewFeature = Cast<ULocomotionFeatureIceBow>(GetFeatureAsClass(ULocomotionFeatureIceBow));
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PlayerComp = UIceBowPlayerComponent::Get(Player);
		MoveComponent =  UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Shoot = PlayerComp.bIsFiringIceBow;

		Charge = PlayerComp.GetChargeFactor();

		if(PlayerComp.AimComp.IsAiming(PlayerComp))
		{
			FAimingResult AimResult = PlayerComp.AimComp.GetAimingTarget(PlayerComp);
			AimAngle = Math::RadiansToDegrees(Math::Asin(AimResult.AimDirection.Z));

        	FIceBowTargetData TargetData = PlayerComp.CalculateTargetData(EIceBowArrowType::Ice);

			// If the target is far away, use trajectory
			// If the target is close, use aim angle
			float DistanceToTargetSquared = TargetData.Origin.DistSquared(TargetData.TargetLocation);
			if(DistanceToTargetSquared > Math::Square(500))
			{
				FVector VelocityDir = TargetData.Velocity.GetSafeNormal();
				ShootAngle = Math::RadiansToDegrees(Math::Asin(VelocityDir.Z));
			}
			else
			{
				ShootAngle = AimAngle;
			}
		}

		bIsMoving = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		bIsIceAim = PlayerComp.GetIsUsingIceBow();

		bIsInAir = MoveComponent.IsInAir();
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

	UFUNCTION(BlueprintOverride)
    float GetBlendTimeToNullFeature() const
    {
        return 0.5;
    }

}
