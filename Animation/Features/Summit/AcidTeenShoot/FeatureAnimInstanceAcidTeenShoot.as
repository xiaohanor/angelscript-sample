UCLASS(Abstract)
class UFeatureAnimInstanceAcidTeenShoot : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAcidTeenShoot Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAcidTeenShootAnimData AnimData;

	// Storing these aim values in two seperate variables because of blending.
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D ShootingBlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimBlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TimeNotShooting;

	UPlayerAcidTeenDragonComponent DragonComp;
	UPlayerAimingComponent AimComp;
	UTeenDragonAcidSprayComponent SprayComp;
	ATeenDragon TeenDragon;
	AHazePlayerCharacter OwningPlayer;

	/*
	 * Angles to use as a buffer when looking behind to avoid flipping between left / right
	 * So e.g. with '5' the aim angles will go up to (180 + 5) 185 and -185 before transitioning to the other side of the blendspace.
	 */
	const float AimBufferSize = 5;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAcidTeenShoot NewFeature = GetFeatureAsClass(ULocomotionFeatureAcidTeenShoot);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		TeenDragon = Cast<ATeenDragon>(HazeOwningActor);
		DragonComp = Cast<UPlayerAcidTeenDragonComponent>(TeenDragon.DragonComponent);
		SprayComp = UTeenDragonAcidSprayComponent::Get(DragonComp.Owner);
		AimComp = UPlayerAimingComponent::Get(DragonComp.Owner);

		OwningPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
	}

	/*
	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.0f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bIsShooting = DragonComp.bIsFiringAcid;

		// Calculate aim values

		if (bIsShooting)
		{
			TimeNotShooting = 0;
			ShootingBlendspaceValues = CalculateAimValues(ShootingBlendspaceValues);
		}
		else
		{
			TimeNotShooting += DeltaTime;
			AimBlendspaceValues = CalculateAimValues(AimBlendspaceValues);

			if (!DragonComp.bTopDownMode)
				AimBlendspaceValues /= 1.5;
		}
	}

	FVector2D CalculateAimValues(const FVector2D& CurrentAimValues)
	{
		FVector2D NewAngles;
		if (AimComp.IsAiming())
		{
			FAimingResult AimResult = AimComp.GetAimingTarget(DragonComp);
			NewAngles = CalculateAimAngles(AimResult.AimDirection, HazeOwningActor.ActorTransform);
		}
		else
		{
			// Fallback to using camera based

			NewAngles = CalculateAimAngles(OwningPlayer.GetViewRotation().ForwardVector, HazeOwningActor.ActorTransform);
		}

		if (NewAngles.X < -180.0 + AimBufferSize || NewAngles.X > 180.0 - AimBufferSize)
		{
			// We're within the buffer, so keep the sign of the previous angles
			if (CurrentAimValues.X > 0 && NewAngles.X < 0)
				NewAngles.X += 360.0; // Convert sign
			else if (CurrentAimValues.X < 0 && NewAngles.X > 0)
				NewAngles.X -= 360.0; // Convert sign
		}

		return NewAngles;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return TimeNotShooting > 0.4;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeToNullFeature() const
	{
		return 0.8;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
