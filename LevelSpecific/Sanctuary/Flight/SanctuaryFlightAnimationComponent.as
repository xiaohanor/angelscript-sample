class USanctuaryFlightAnimationComponent : UActorComponent
{
	FHazeAcceleratedVector2D AccBlendSpaceValues;
	TInstigated<float> BlendSpaceHorizontal;
	TInstigated<float> BlendSpaceVertical;
	TInstigated<float> BlendSpaceAccelerationDuration;

	FVector2D WantedDirection;

	FVector2D BlendSpaceAcceleration;

	UFUNCTION()
	FVector2D GetMovementBlendSpaceValue() property
	{
		return AccBlendSpaceValues.Value;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector2D TargetBlendSoace = FVector2D(BlendSpaceHorizontal.Get(), BlendSpaceVertical.Get());
		AccBlendSpaceValues.AccelerateTo(TargetBlendSoace, BlendSpaceAccelerationDuration.Get(), DeltaTime);
	}

	void SnapMovementBlendSpaceValues()
	{
		FVector2D TargetBlendSoace = FVector2D(BlendSpaceHorizontal.Get(), BlendSpaceVertical.Get());
		AccBlendSpaceValues.SnapTo(TargetBlendSoace, FVector2D::ZeroVector);
	}
}
