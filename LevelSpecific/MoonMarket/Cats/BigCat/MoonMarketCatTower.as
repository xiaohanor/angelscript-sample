class AMoonMarketCatTower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UInheritVelocityComponent InheritVelocityComp;

	FVector StartLocation;
	
	UPROPERTY(EditInstanceOnly)
	float ZOffset = 120.0;

	UPROPERTY(EditInstanceOnly)
	float SinOffset = 0.0;

	UPROPERTY(EditInstanceOnly)
	float SinSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorRelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorRelativeLocation = StartLocation + FVector::UpVector * Math::Sin(SinOffset + (Time::GameTimeSeconds * SinSpeed)) * ZOffset;
	}
};