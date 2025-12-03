struct FLocomotionFeatureShoulderCannonAnimData
{
	UPROPERTY(Category = "ShoulderCannon")
	FHazePlaySequenceData NotAiming;

	UPROPERTY(Category = "ShoulderCannon")
	FHazePlaySequenceData EnterAiming;

	UPROPERTY(Category = "ShoulderCannon")
	FHazePlayBlendSpaceData Aiming;

	UPROPERTY(Category = "ShoulderCannon")
	FHazePlayBlendSpaceData Shooting;

	UPROPERTY(Category = "ShoulderCannon")
	FHazePlaySequenceData ExitAiming;
}



UCLASS(Abstract)
class UFeatureAnimInstanceShoulderCannon : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly)
	FLocomotionFeatureShoulderCannonAnimData AnimData;
	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAiming;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToShoot;
	
	UPlayerAimingComponent AimComp;

	ACoastShoulderTurret TurretActor; 

	/* 
	* Angles to use as a buffer when looking behind to avoid flipping between left / right
	* So e.g. with '5' the aim angles will go up to (180 + 5) 185 and -185 before transitioning to the other side of the blendspace. 
	*/
	const float AimBufferSize = 20;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		// Get components here...

		TurretActor = Cast <ACoastShoulderTurret>(HazeOwningActor);
		if(TurretActor==nullptr)
			return; 
		
		AimComp = UPlayerAimingComponent::Get(TurretActor.Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	

		
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		// Implement Custom Stuff Here

		bAiming = TurretActor.IsAiming();
		bWantsToShoot = TurretActor.IsShooting();


		// Calculate aim values
		if (AimComp.IsAiming())
		{
			const auto AimTarget = AimComp.GetAimingTarget(TurretActor.Player);
			const FVector TowardsTargetTurretSpace = TurretActor.ActorTransform.InverseTransformVectorNoScale(AimTarget.AimDirection);
			const FRotator AimAngles = FRotator::MakeFromXZ(TowardsTargetTurretSpace, TurretActor.Player.ActorUpVector);

			FVector2D NewAngles = FVector2D(AimAngles.Yaw, AimAngles.Pitch);
			if (NewAngles.X < -180.0 + AimBufferSize || NewAngles.X > 180.0 - AimBufferSize)
			{
				// We're within the buffer, so keep the sign of the previous angles
				if (AimValues.X > 0 && NewAngles.X < 0)
					NewAngles.X += 360.0; // Convert sign
				else if (AimValues.X < 0 && NewAngles.X > 0)
					NewAngles.X -= 360.0; // Convert sign
			}
				AimValues = NewAngles;
		}
	}

	
}
