class USkylineBasketballResponseComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float Dampening = 0.8;

	UPROPERTY(EditAnywhere)
	FVector ExtraImpulse = FVector::UpVector * 200.0;

	UPROPERTY(EditAnywhere)
	FVector RedirectVelocity = FVector::UpVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	FVector GetDampedVelocity(FVector Velocity)
	{
		FVector NewVelocity = Velocity;
		NewVelocity *= (1.0 - Dampening);
		NewVelocity += ExtraImpulse;
		NewVelocity = RedirectVelocity.SafeNormal * NewVelocity.Size();

		return NewVelocity;
	}
};