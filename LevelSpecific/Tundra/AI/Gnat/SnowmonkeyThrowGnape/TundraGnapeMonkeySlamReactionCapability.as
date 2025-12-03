class UTundraGnapeMonkeySlamReactionCapabilty : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local; // Control side only
	default CapabilityTags.Add(n"MonkeySlamReaction");
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UTundraPlayerSnowMonkeyGroundSlamResponseComponent MonkeySlamComp = nullptr;
	UTundraGnatComponent GnapeComp;
	UTundraGnatSettings Settings;

	FVector SlamImpulse = FVector::ZeroVector;
	float SlamTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GnapeComp = UTundraGnatComponent::Get(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MonkeySlamComp != nullptr)
			return;
		MonkeySlamComp = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::Get(Owner);
		if (MonkeySlamComp != nullptr)
			MonkeySlamComp.OnGroundSlam.AddUFunction(this, n"OnMonkeySlam");
	}

	UFUNCTION()
	private void OnMonkeySlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		SlamTime = Time::GameTimeSeconds;
		FVector Away = Owner.ActorLocation - PlayerLocation;
		SlamImpulse = Away.GetSafeNormal() * Math::RandRange(0.5, 1.0) * Settings.MonkeyGroundSlamMaxForce;
		SlamImpulse.Z += Math::RandRange(0.8, 1.0) * Settings.MonkeyGroundSlamExtraHeight;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (Time::GetGameTimeSince(SlamTime) > 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GnapeComp.bGoBallistic = true;
		Owner.AddMovementImpulse(SlamImpulse);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SlamTime = -BIG_NUMBER;
	}
}
