class UDentistBossTargetComponent : UActorComponent
{
	ADentistBoss Dentist;

	// TODO: add access specifier for this and select capability for edit
	TInstigated<AHazePlayerCharacter> Target;
	FVector LookTargetLocation;
	bool bOverrideLooking = false;

	AHazePlayerCharacter CupRestrainedPlayer;
	AHazePlayerCharacter LastPlayerHooked;

	TArray<AHazePlayerCharacter> DrillTargets;
	TPerPlayer<bool> IsOnCake;
	float DrillTelegraphDelay = 0.0;
	bool bIsDrilling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		auto Cake = Dentist.Cake;

		Cake.PlayerOnCakeTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterOnCakeTrigger");
		Cake.PlayerOnCakeTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeaveOnCakeTrigger");

		LookTargetLocation = Dentist.Cake.ActorLocation;
	}

	UFUNCTION()
	private void OnPlayerEnterOnCakeTrigger(AHazePlayerCharacter Player)
	{
		IsOnCake[Player] = true;
	}

	UFUNCTION()
	private void OnPlayerLeaveOnCakeTrigger(AHazePlayerCharacter Player)
	{
		IsOnCake[Player] = false;
	}

	void LookAtTarget(FVector TargetLocation)
	{
		// FVector HeadDirToTarget = (TargetLocation - Dentist.HeadRoot.WorldLocation).GetSafeNormal();
		// Dentist.HeadRoot.WorldRotation = FRotator::MakeFromX(HeadDirToTarget);

		// FVector LightDirToTarget = (TargetLocation - Dentist.HeadLightSpotlight.WorldLocation).GetSafeNormal();
		// Dentist.HeadLightSpotlight.WorldRotation = FRotator::MakeFromX(LightDirToTarget);

		LookTargetLocation = TargetLocation;
	}
};