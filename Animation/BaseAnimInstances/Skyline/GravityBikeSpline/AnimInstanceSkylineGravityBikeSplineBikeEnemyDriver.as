UCLASS(Abstract)
class UAnimInstanceSkylineGravityBikeSplineBikeEnemyDriver : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSplineBikeEnemyDriver Driver;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDriving = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrabbed = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bThrown = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDropped = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float Throttle = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float Steer = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasPistol = false;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Pistol")
	float PistolAimAngleHorizontal;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Pistol")
	float PistolAimAngleVertical;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Driver == nullptr)
			return;

		bDriving = Driver.State == EGravityBikeSplineBikeEnemyDriverState::Driving;
		bGrabbed = Driver.State == EGravityBikeSplineBikeEnemyDriverState::Grabbed;
		bThrown = Driver.State == EGravityBikeSplineBikeEnemyDriverState::Thrown;
		bDropped = Driver.State == EGravityBikeSplineBikeEnemyDriverState::Dropped;

		UpdateDriving();
		UpdatePistol();
	}

	void UpdateDriving()
	{
		if(Driver.Bike == nullptr)
			return;

		if(!bDriving)
			return;

		Throttle = Driver.Bike.SplineMoveComp.GetThrottle();
		Steer = Driver.Bike.AccRoll.Value / (Driver.Bike.TiltMax * 0.5);
	}

	void UpdatePistol()
	{
		auto PistolComp = UGravityBikeSplineBikeEnemyDriverPistolComponent::Get(Driver);
		if(PistolComp == nullptr)
		{
			bHasPistol = false;
			return;
		}

		bHasPistol = true;

		FVector TargetLocation = PistolComp.GetTargetLocation();
		FVector RelativeTargetLocation = Driver.ActorTransform.InverseTransformPositionNoScale(TargetLocation);
		FRotator RelativeRotation = FRotator::MakeFromXZ(
			RelativeTargetLocation,
			FVector::UpVector
		);

		PistolAimAngleHorizontal = RelativeRotation.Yaw;
		PistolAimAngleVertical = RelativeRotation.Pitch;

		// PrintToScreen(f"{PistolAimAngleHorizontal=}");
		// PrintToScreen(f"{PistolAimAngleVertical=}");
	}
}