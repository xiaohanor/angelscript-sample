class UCentipedeBodyDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::LastDemotable;
	default DebugCategory = CentipedeTags::Centipede;

	ACentipede Centipede;

	const float DissolveDuration = 0.5;
	const float MaterializeDuration = 0.8;

	bool bRevive = false;
	float ReviveTimer;

	bool bFadeOut;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Centipede = Cast<ACentipede>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Centipede.IsDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bRevive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block movement while we are reviving
		for (auto Player : Game::Players)
		{
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.FadeOut(this);
		}

		bFadeOut = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Centipede.Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", 0);

		ReviveTimer = 0;
		bRevive = false;

		// Allow movement once again
		for (auto Player : Game::Players)
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Dissolve;
		if (Centipede.IsDead())
		{
		 	Dissolve = Math::Saturate(ActiveDuration / DissolveDuration) * 0.5;
		}
		else
		{
			Dissolve = 0.5 - (Math::Square(Math::Saturate(ReviveTimer / MaterializeDuration)) * 0.5);

			if (ReviveTimer >= MaterializeDuration * 1.5)
				bRevive = true;

			ReviveTimer += DeltaTime;

			if (!HasControl() || !Network::IsGameNetworked())
			{
				if (bFadeOut)
				{
					NetRemoteReadyForFadeClear();
				}
			}
		}

		Centipede.Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", Dissolve);
	}

	// Called from remote to poke control side
	UFUNCTION(NetFunction)
	void NetRemoteReadyForFadeClear()
	{
		if (HasControl())
			NetFadeClear();
	}

	UFUNCTION(NetFunction)
	void NetFadeClear()
	{
		bFadeOut = false;

		for (auto Player : Game::Players)
		{
			Player.ClearFade(this);
			UCameraUserComponent::Get(Player).SnapCamera();
		}
	}
}