namespace Desert
{
	UFUNCTION()
	bool AreBothPlayersRidingGrapplefish()
	{
		for (auto Player : Game::Players)
		{
			auto Comp = UDesertGrappleFishPlayerComponent::Get(Player);
			if (Comp.State != EDesertGrappleFishPlayerState::Riding)
				return false;
		}
		return true;
	}

	UFUNCTION()
	void TeleportPlayersToGrappleFish(FInstigator Instigator)
	{
		for (auto GrappleFish : TListedActors<ADesertGrappleFish>())
		{
			auto Players = Game::GetPlayersSelectedBy(GrappleFish.GrapplePointComp.UsableByPlayers);
			Players[0].TeleportActor(GrappleFish.GrapplePointComp.WorldLocation, GrappleFish.GrapplePointComp.WorldRotation, n"TeleportToGrappleFish", true);
			Perch::TeleportPlayerOntoPerch(Players[0], Instigator, GrappleFish.GrapplePointComp);
			GrappleFish.State.Apply(EDesertGrappleFishState::Mounted, Instigator, EInstigatePriority::Override);
			Players[0].SetActorRotation(GrappleFish.GrapplePointComp.WorldRotation);
			GrappleFish.bIsMovingTowardsEnd = true;
		}
	}

	UFUNCTION()
	void BlockSandDeath(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Player.BlockCapabilities(n"OnSandDeath", Instigator);
	}

	UFUNCTION()
	void StartGrappleFishJumpTutorial(AHazePlayerCharacter Player)
	{
		UDesertGrappleFishPlayerComponent PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		if (!PlayerComp.bTutorialCompleted)
			PlayerComp.bTutorialStarted = true;
	}

	UFUNCTION()
	void TriggerEndJump(AHazePlayerCharacter Player)
	{
		UDesertGrappleFishPlayerComponent PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		PlayerComp.GrappleFish.TriggerEndJump();
		PlayerComp.TriggerEndJump();
	}

	UFUNCTION()
	void ApplyGrappleFishRespawnOverrides()
	{
		for (auto Player : Game::Players)
		{
			Player.ResetStickyRespawnPoints();
		}
		for (auto GrappleFish : TListedActors<ADesertGrappleFish>().Array)
		{
			GrappleFish.ApplyRespawnOverride();
		}
	}

	// UFUNCTION()
	// void ForceLaunchFromGrappleFish(AHazePlayerCharacter Player)
	// {
	// 	UDesertGrappleFishPlayerComponent PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
	// 	PlayerComp.LaunchFromGrappleFish(false);
	// }
}