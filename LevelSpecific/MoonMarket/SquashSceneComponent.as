class USquashSceneComponent : USceneComponent
{
	FVector BounceScale = FVector::OneVector;
	float BounceTime;
	float Stiffness;
	float Damping;
	bool bCanBounce;

	FHazeAcceleratedVector AcceleratedVector;
	default AcceleratedVector.Value = FVector::OneVector;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector NewScale = RelativeScale3D;
		BounceTime -= DeltaSeconds;

		if (BounceTime > 0.0)
		{
			NewScale = Math::VInterpConstantTo(NewScale, BounceScale, DeltaSeconds, 10.0);
			AcceleratedVector.SpringTo(NewScale, Stiffness, Damping, DeltaSeconds);
		}
		else
		{
			NewScale = Math::VInterpConstantTo(NewScale, FVector::OneVector, DeltaSeconds, 6.0);
			AcceleratedVector.SpringTo(FVector::OneVector, Stiffness, Damping, DeltaSeconds);
		}

		SetRelativeScale3D(AcceleratedVector.Value);
	}

	void SetBounce(float _BounceTime, float _Stiffness, float _Damping)
	{
		BounceTime = _BounceTime;
		Stiffness = _Stiffness;
		Damping = _Damping;
		bCanBounce = true;
	}
}