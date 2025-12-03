class UAISummitTotemTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AISummitTotemTargetingCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AAISummitTotem Totem;

	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Totem = Cast<AAISummitTotem>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelRot.SnapTo(Totem.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Totem.Target = GetTarget();

		if (Totem.Target != nullptr)
		{
			FRotator LookAt = (GetTarget().ActorLocation - Totem.ActorLocation).GetSafeNormal().Rotation();
			AccelRot.AccelerateTo(LookAt, 1.0, DeltaTime);
			Totem.ActorRotation = AccelRot.Value;
		}
		else
		{
			PrintToScreen("Target Nullptr");
		}
	}

	AHazePlayerCharacter GetTarget()
	{
		float MioDist = Totem.GetDistanceTo(Game::Mio);
		float ZoeDist = Totem.GetDistanceTo(Game::Zoe);

		if (PlayerInRange(Game::Mio) && PlayerInRange(Game::Zoe))
			return MioDist > ZoeDist ? Game::Zoe : Game::Mio;
		else if (PlayerInRange(Game::Mio) && !PlayerInRange(Game::Zoe))
			return Game::Mio;
		else if (!PlayerInRange(Game::Mio) && PlayerInRange(Game::Zoe))
			return Game::Zoe;
		
		return nullptr;
	}

	bool PlayerInRange(AHazePlayerCharacter Player)
	{
		float Dist = Totem.GetDistanceTo(Player);
		return Dist < Totem.MaxTargetDist;
	}
}