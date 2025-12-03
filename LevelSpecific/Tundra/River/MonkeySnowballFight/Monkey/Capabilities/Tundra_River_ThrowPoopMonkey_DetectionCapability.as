class UTundra_River_ThrowPoopMonkey_DetectionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	ATundra_River_ThrowPoopMonkey Monkey;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ATundra_River_ThrowPoopMonkey>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.ClosestPlayerInRange == nullptr)
			return false;

		if(Monkey.State == ETundraPoopMonkeyState::Throwing || Monkey.State == ETundraPoopMonkeyState::Hit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.ClosestPlayerInRange == nullptr)
			return true;

		if(Monkey.State == ETundraPoopMonkeyState::Throwing || Monkey.State == ETundraPoopMonkeyState::Hit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.State = ETundraPoopMonkeyState::PlayerDetected;
		Monkey.NextThrowTime = Time::GameTimeSeconds + Math::RandRange(0.5, 4);
		UTundra_River_PoopMonkeyEventHandler::Trigger_OnDetectPlayer(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// FRotator ToPlayer = (Monkey.ClosestPlayerInRange.ActorLocation - Owner.ActorLocation).VectorPlaneProject(FVector::UpVector).ToOrientationRotator();
		// FRotator Rotation = Math::RInterpConstantTo(Owner.ActorRotation, ToPlayer, DeltaTime, Monkey.TurnSpeed);
		// Owner.SetActorRotation(Rotation);
	}
};