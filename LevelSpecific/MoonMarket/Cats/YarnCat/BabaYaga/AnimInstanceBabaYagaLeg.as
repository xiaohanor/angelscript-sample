class UAnimInstanceBabaYagaLeg : UHazeAnimInstanceBase
{
	ABabaYagaLeg Leg;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector FootPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator FootRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector BasePosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ClawGrip;

	bool bIsStanding = false;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Leg = Cast<ABabaYagaLeg>(HazeOwningActor);
		FootPosition = Leg.FootTargetLocation;
		FootRotation = Leg.FootTargetRotation;
		BasePosition = Leg.BaseTargetLocation;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Leg == nullptr)
		{
			Leg = Cast<ABabaYagaLeg>(HazeOwningActor);
			return;
		}

		bIsStanding = Leg.bIsStanding;

		FootPosition = Leg.CurrentFootLocation;
		FootRotation = Leg.FootTargetRotation;
		BasePosition = Leg.CurrentBaseLocation;
		ClawGrip = Leg.ClawGrip;


		if(bIsStanding)
		{
			float Multiplier = Math::Sin((Time::GetGameTimeSince(Leg.AnimStartTime) * Leg.RollSwaySpeed * 2));
			float CurrentHeightOffset = Leg.HeightBobAmount * Multiplier;
			BasePosition.Z += CurrentHeightOffset;
			BasePosition.X += CurrentHeightOffset;
		}
	}

	void SetValues(FVector NewFootPosition, FRotator NewFootRotation, FVector NewBasePosition)
	{
		FootPosition = NewFootPosition;
		FootRotation = NewFootRotation;
		BasePosition = NewBasePosition;
	}
}