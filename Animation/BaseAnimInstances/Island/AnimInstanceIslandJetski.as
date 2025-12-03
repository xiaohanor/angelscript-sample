class UAnimInstanceIslandJetski : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData SolidGroundAdditive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SolidGroundAdditiveAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SpringOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SpringRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SpringOffset2;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SpringRotation2;

	AJetski Jetski;

	FVector LocalVelocity;

	FHazeAcceleratedFloat Spring;
	FHazeAcceleratedFloat Spring2;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Jetski = Cast<AJetski>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Jetski == nullptr)
			return;

		LocalVelocity = Jetski.GetActorLocalVelocity();

		SolidGroundAdditiveAlpha = Jetski.GetMovementState() == EJetskiMovementState::Ground ? BlendspaceValues.Y : 0;
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void BlueprintThreadSafeUpdateAnimation(float DeltaTime)
	{
		BlendspaceValues.Y = Math::Clamp(LocalVelocity.Size2D() / 2000, 0.0, 1.0);

		const float UpDownMovement = Math::Clamp(LocalVelocity.Z / 1000, -1.0, 1.0);

		CalculateSpring(Spring, UpDownMovement, 45, 0.3, DeltaTime);
		CalculateSpring(Spring2, UpDownMovement, 25, 0.25, DeltaTime);

		SpringOffset.Z = Spring.Value * -14;
		SpringRotation.Pitch = Spring.Value * -9;

		SpringOffset2.Z = Spring2.Value * -10;
		SpringRotation2.Pitch = Spring2.Value * -13;
	}

	void CalculateSpring(FHazeAcceleratedFloat& AcceleratedFloat, float Target, float Stiffness, float Damping, float DeltaTime)
	{
		AcceleratedFloat.SpringTo(Target, Stiffness, Damping, DeltaTime);
		if (Math::Abs(AcceleratedFloat.Value) > 1.6)
		{
			AcceleratedFloat.Value = Math::Sign(AcceleratedFloat.Value) * 1.6;
			AcceleratedFloat.Velocity = 0;
		}
	}
}