UCLASS(Abstract)
class APrisonGuardBotZapperProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	bool bMoving = false;
	FVector TargetLocation;

	float MaxMoveDuration = 1.0;
	float CurrentMoveDuration = 0.0;

	void Shoot(FVector Loc)
	{
		TargetLocation = Loc;
		CurrentMoveDuration = 0.0;
		BP_Shoot();
		bMoving = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Shoot() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoving)
			return;

		CurrentMoveDuration += DeltaTime;
		FVector Loc = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaTime, 20000.0);
		SetActorLocation(Loc);
		if (ActorLocation.Equals(TargetLocation) || CurrentMoveDuration >= MaxMoveDuration)
		{
			bMoving = false;
			BP_Impact();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() {}
}