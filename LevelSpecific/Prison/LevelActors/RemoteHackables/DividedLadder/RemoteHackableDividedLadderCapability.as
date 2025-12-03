class URemoteHackableDividedLadderCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ARemoteHackableDividedLadder Ladder;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Ladder = Cast<ARemoteHackableDividedLadder>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if(HasControl())
			Player.ForceEnterLadder(Ladder.RealLadder);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			float HackableOffset = Ladder.SyncedHackableOffset.Value + (Input.X * 160.0 * DeltaTime);
			HackableOffset = Math::Clamp(HackableOffset, 200.0, Ladder.MaxHackableOffset);
			Ladder.SyncedHackableOffset.SetValue(HackableOffset);
		}
	}
}