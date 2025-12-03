class UTundraBossSetupPounceCapability : UTundraBossSetupChildCapability
{
	bool bAnimationHasBreachedIce = false;
	float TimeDilation = 1;
	float TargetSlowmotion = 1;
	bool bHasActivatedAirborneGroundSlam = false;
	bool bHasActivatedTutorialPrompt = false;
	float InterpSpeed = 0.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossSetupStates::Pounce)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(bHasActivatedAirborneGroundSlam)
		// 	return true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.DeathVolume.DisableDeathVolume(this);
		UTundraBossSetup_EffectHandler::Trigger_OnPounce(Boss);

		// for (auto Player : Game::GetPlayers())
		// 	Player.PlayCameraShake(Boss.PounceLong, this);
		
		if (HasControl())
			Boss.CrumbActivatePounceAttack(ETundraBossSetupAttackAnim::Pounce, Boss.IceBreachActor.ActorTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// if (HasControl())
		// 	Boss.CrumbProgressQueue();
		Boss.CrumbProgressQueue();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(!bAnimationHasBreachedIce)
		// {
		// 	if(ActiveDuration > 1)
		// 	{
		// 		bAnimationHasBreachedIce = true;

		// 		Game::Mio.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player, true);
		// 		Game::Zoe.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player, true);
		// 		Game::Zoe.AddMovementImpulseToReachHeight(2000, true, NAME_None);
		// 		Game::Mio.AddMovementImpulseToReachHeight(2000, true, NAME_None);
		// 		Game::Mio.SetActorHorizontalVelocity(FVector(0,0,0));
		// 		Game::Zoe.SetActorHorizontalVelocity(FVector(0,0,0));
		// 		TundraBossSetupIceFloor::GetIceFloor().BreakIceFloor();
		// 		Boss.IceFloorNew.SimulationLevelSequences[0].PlayLevelSequenceSimple();

		// 		for (auto Player : Game::GetPlayers())
		// 			Player.PlayCameraShake(Boss.PounceImpact, this);
		// 	}
		// }
		// else if (ActiveDuration >= 2)
		// {
		// 	bHasActivatedAirborneGroundSlam = true;
		// }
	}

	// UFUNCTION(CrumbFunction)
	// void CrumbActivateGroundSlam()
	// {
	// 	bHasActivatedAirborneGroundSlam = true;
	// 	Game::GetMio().RemoveTutorialPromptByInstigator(this);
	// }
};

