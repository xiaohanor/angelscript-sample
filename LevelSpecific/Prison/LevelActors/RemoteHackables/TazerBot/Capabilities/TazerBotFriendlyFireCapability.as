class UTazerBotFriendlyFireCapability : UHazeCapability
{
	default CapabilityTags.Add(PrisonTags::Prison);

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	ATazerBot TazerBot;
	AHazePlayerCharacter Player;

	UPlayerKnockdownComponent OtherPlayerKnockdownComponent;
	UPlayerPerchComponent OtherPlayerPerchComponent;

	// Minimum torque magnitude to knockdown player
	const float MinKnockdownShaftTorque = 50.0;

	bool bOtherPlayerTipped;
	bool bIgnoreKnockdownCollision;

	bool bPlayerIgnoringTazerCollision;

	bool bHasEverKnockedDownPlayer = false;
	bool bHasEverKilledPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.IsHacked())
			return false;

		if (TazerBot.bDestroyed)
			return false;

		if (TazerBot.bRespawning)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TazerBot.IsHacked())
			return true;

		if (TazerBot.bDestroyed)
			return true;

		if (TazerBot.bRespawning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = TazerBot.HackingPlayer;

		OtherPlayerKnockdownComponent = UPlayerKnockdownComponent::Get(Player.OtherPlayer);
		OtherPlayerPerchComponent = UPlayerPerchComponent::Get(Player.OtherPlayer);

		bOtherPlayerTipped = false;
		bIgnoreKnockdownCollision = false;
		bPlayerIgnoringTazerCollision = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bPlayerIgnoringTazerCollision)
		{
			UPlayerMovementComponent::Get(Player.OtherPlayer).RemoveMovementIgnoresActor(this);
			bPlayerIgnoringTazerCollision = false;
		}

		Player = nullptr;
		OtherPlayerKnockdownComponent = nullptr;
	}

	// Eman TODO: Add a bullshit network (local visuals) behaviour for knockdown and tazer
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CanTroll())
			return;

		if (bOtherPlayerTipped)
			return;

		if (TryTip())
			return;

		if (bIgnoreKnockdownCollision)
		{
			if (!OtherPlayerKnockdownComponent.IsPlayerKnockedDown())
			{
				UPlayerMovementComponent::Get(Player.OtherPlayer).RemoveMovementIgnoresActor(this);

				bPlayerIgnoringTazerCollision = false;
				bIgnoreKnockdownCollision = false;
			}
		}
		else if (TryShaft())
		{
			if (!bPlayerIgnoringTazerCollision)
			{
				UPlayerMovementComponent::Get(Player.OtherPlayer).AddMovementIgnoresActor(this, TazerBot);

				// bPlayerIgnoringTazerCollision = true;
				bIgnoreKnockdownCollision = true;
			}

			return;
		}
	}

	// Giggity
	bool TryTip()
	{
		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(TazerBot.PlayerTipCollider);
		Trace.IgnoreActor(TazerBot);
		Trace.IgnoreActor(Player);

		// Look for other player with tip
		for (auto Overlap : Trace.QueryOverlaps(TazerBot.PlayerTipCollider.WorldLocation))
		{
			if (Overlap.Actor != Player.OtherPlayer)
				continue;

			bOtherPlayerTipped = true;
			KillPlayer();

			return true;
		}

		return false;
	}

	UFUNCTION()
	private void KillPlayer()
	{
		Player.OtherPlayer.KillPlayer(FPlayerDeathDamageParams(TazerBot.PerchRoot.ForwardVector), TazerBot.PlayerZapDeathEffect);

		bOtherPlayerTipped = false;

		// Committed tazer muder
		FTazerBotOnPlayerKilledByTazerParams Params;
		Params.TazeredPlayer = Player.OtherPlayer;
		UTazerBotEventHandler::Trigger_OnPlayerKilledByTazer(TazerBot, Params);

		bHasEverKilledPlayer = true;
		if (bHasEverKnockedDownPlayer)
			Online::UnlockAchievement(n"TazerBotKill");
	}

	// Giggity goo!
	bool TryShaft()
	{
		// Don't evaluate if collision speed was not enough
		{
			if (Math::IsNearlyZero(TazerBot.CrumbedAngularSpeed.Value))
				return false;

			float Torque = TazerBot.CrumbedAngularSpeed.Value * TazerBot.GetDistanceTo(Player.OtherPlayer);
			if (Torque < MinKnockdownShaftTorque)
				return false;
		}

		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(TazerBot.PlayerTelescopeCollision);
		Trace.IgnoreActor(TazerBot);
		Trace.IgnoreActor(Player);

		// Look for other player along shaft
		for (auto Overlap : Trace.QueryOverlaps(TazerBot.PlayerTelescopeCollision.WorldLocation))
		{
			if (Overlap.Actor != Player.OtherPlayer)
				continue;

			// Get toss direction
			FVector PlayerToOtherPlayer = (Player.OtherPlayer.ActorLocation - TazerBot.ActorLocation);
			FVector TossDirection = PlayerToOtherPlayer.ConstrainToDirection(TazerBot.ActorRightVector).GetSafeNormal();

			FKnockdown Knockdown;
			Knockdown.Move = TossDirection;
			Knockdown.Duration = TazerBot.KnockdownParams.Duration;
			Knockdown.StandUpDuration = TazerBot.KnockdownParams.StandUpDuration;

			Player.OtherPlayer.ApplyKnockdown(Knockdown);
			Player.OtherPlayer.PlayCameraShake(TazerBot.KnockdownCamShake, this);
			Player.OtherPlayer.PlayForceFeedback(TazerBot.KnockDownFF, false, true, this);

			FTazerBotOnPlayerKnockedDownByTelescopeArmParams EffectEventParams;
			EffectEventParams.KnockedPlayer = Player.OtherPlayer;
			EffectEventParams.KnockdownDuration = Knockdown.Duration;
			EffectEventParams.StandUpDuration = Knockdown.StandUpDuration;
			UTazerBotEventHandler::Trigger_OnPlayerKnockedDownByTelescopeArm(TazerBot, EffectEventParams);

			Player.PlayForceFeedback(TazerBot.KnockDownFF, this);

			bHasEverKnockedDownPlayer = true;
			if (bHasEverKilledPlayer)
				Online::UnlockAchievement(n"TazerBotKill");

			return true;
		}

		return false;
	}

	bool CanTroll() const
	{
		if (!TazerBot.bExtended)
			return false;

		if (TazerBot.bLaunched)
			return false;

		if (TazerBot.MovementComponent.IsInAir())
			return false;

		if (OtherPlayerPerchComponent.GetState() != EPlayerPerchState::Inactive)
			return false;

		if (Player.OtherPlayer.IsPlayerDead())
			return false;

		if (Player.OtherPlayer.IsPlayerRespawning())
			return false;

		return true;
	}
}