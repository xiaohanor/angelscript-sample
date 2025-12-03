class UAnimInstanceTundraPoopMonkey : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ThrowPoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Hit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrowPoop;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnableLookAt;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LookAtLocation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SpineRotation;

	ATundra_River_ThrowPoopMonkey Monkey;

	AHazeActor LookAtTarget;

	float UpdateLookAtTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Monkey = Cast<ATundra_River_ThrowPoopMonkey>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Monkey == nullptr)
			return;

		bHit = GetAnimTrigger(n"Hit");

		bThrowPoop = GetAnimTrigger(n"Throw");
		if (bThrowPoop)
			UpdateLookAtTimer = 0;

		if (LookAtTarget == nullptr && Monkey.ClosestPlayerInRange != nullptr)
		{
			LookAtTarget = Monkey.ClosestPlayerInRange;
			UpdateLookAtTimer = 2;
		}

		UpdateLookAtTimer -= DeltaTime;

		if (UpdateLookAtTimer <= 0)
		{
			if (Monkey.TargetPlayer != nullptr)
				LookAtTarget = Monkey.TargetPlayer;
			else
				LookAtTarget = Monkey.ClosestPlayerInRange;
			UpdateLookAtTimer = Math::RandRange(2, 5);
		}

		bEnableLookAt = LookAtTarget != nullptr;
		float AimAngle = 0;
		if (bEnableLookAt)
		{
			LookAtLocation = LookAtTarget.ActorLocation;

			FVector Dir = (LookAtLocation - HazeOwningActor.ActorLocation);
			Dir.Z = 0;

			const float ForwDot = Dir.DotProduct(HazeOwningActor.ActorForwardVector);
			const float RightDot = Dir.DotProduct(HazeOwningActor.ActorRightVector);
			AimAngle = Math::RadiansToDegrees(Math::Atan2(RightDot, ForwDot));
		}

		SpineRotation.Yaw = Math::FInterpTo(SpineRotation.Yaw,
											Math::Clamp(AimAngle, -90.0, 90.0),
											DeltaTime,
											2);
	}
}