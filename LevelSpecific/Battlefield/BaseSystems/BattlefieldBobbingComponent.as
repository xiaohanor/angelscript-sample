class UBattlefieldBobbingComponent : UActorComponent
{
	FVector Origin;

	UPROPERTY(EditAnywhere)
	float Speed = 1.5;

	UPROPERTY(EditAnywhere)
	float ZAmount = 450.0;

	float Randomness;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Origin = Owner.ActorLocation;
		Randomness = Math::RandRange(0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ZAdd = Math::Sin((Randomness + Time::GameTimeSeconds) * Speed) * ZAmount;
		Owner.ActorLocation = Origin + (FVector::UpVector * ZAdd);
	}
};