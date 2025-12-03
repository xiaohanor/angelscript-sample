UCLASS(Abstract)
class UAnimInstanceSkylineGravityBikeSplineBikeEnemy : UHazeAnimInstanceBase
{
	AGravityBikeSplineBikeEnemy BikeEnemy;

	UPROPERTY(BlueprintReadOnly)
	float Speed = 0;

	UPROPERTY(BlueprintReadOnly)
	float MovedDistance = 0;
	
	UPROPERTY(BlueprintReadOnly)
	FQuat WheelRotation;

	const float WHEEL_RADIUS = 38;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(HazeOwningActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(BikeEnemy == nullptr)
			return;

		Speed = BikeEnemy.SplineMoveComp.Speed;
		MovedDistance += Speed * DeltaTime;

		WheelRotation = FQuat(FVector::RightVector, MovedDistance / WHEEL_RADIUS);
	}
}