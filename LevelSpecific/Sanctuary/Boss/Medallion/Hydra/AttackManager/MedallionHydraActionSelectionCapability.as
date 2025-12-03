enum EMedallionHydraAttack
{
	BasicProjectileSingle,
	BasicProjectileTripple,
	SplittingProjectile,
	SplittingSetOffsetProjectile,
	SplittingProjectileQuad,
	SplittingProjectileTriple,
	FlyingProjectile,
	ArcSpray,
	RainAttack,
	ChaseLaser,
	SlashLaser,
	AboveProjectile,
	FlyingSlashLaser,
	LaneLaser1,
	LaneLaser2,
	LaneLaser3,
	LaneLaserAbove1,
	LaneLaserAbove2,
	LaneLaserAbove3,
	BallistaProjectile,
	Wave,
	SidescrollerSpam,
	Meteor
}

class UMedallionHydraActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMedallionHydraAttackManager Manager;
	UHazeActionQueueComponent QueueComp;
	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UMedallionPlayerMergeHighfiveJumpComponent MioHighfiveComp;
	UMedallionPlayerMergeHighfiveJumpComponent ZoeHighfiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AMedallionHydraAttackManager>(Owner);
		QueueComp = Manager.QueueComp;
		Manager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
		Mio = Game::Mio;
		Zoe = Game::Zoe;
		MioHighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Mio);
		ZoeHighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Zoe);

		MioHighfiveComp.OnHighfiveStart.AddUFunction(this, n"HandleHighfiveStarted");
		ZoeHighfiveComp.OnHighfiveStart.AddUFunction(this, n"HandleHighfiveStarted");
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (bNaturalProgression)
		{
			if (Phase == EMedallionPhase::Sidescroller1)
				QueueComp.Idle(2.0);
			if (Phase == EMedallionPhase::Sidescroller2)
				QueueComp.Idle(2.0);
			if (Phase == EMedallionPhase::Sidescroller3)
				QueueComp.Idle(2.0);

			if (Phase == EMedallionPhase::BallistaPlayersAiming1)
				QueueComp.Empty();
			if (Phase == EMedallionPhase::BallistaArrowShot1)
				QueueComp.Empty();
			if (Phase == EMedallionPhase::BallistaPlayersAiming2)
				QueueComp.Empty();
			if (Phase == EMedallionPhase::BallistaArrowShot2)
				QueueComp.Empty();
			if (Phase == EMedallionPhase::BallistaPlayersAiming3)
				QueueComp.Empty();
			if (Phase == EMedallionPhase::BallistaArrowShot3)
				QueueComp.Empty();
		}
	}

	UFUNCTION()
	private void HandleHighfiveStarted()
	{
		QueueComp.Empty();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Mio.bIsControlledByCutscene || Zoe.bIsControlledByCutscene)
			return false;
		if (QueueComp.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Mio.bIsControlledByCutscene || Zoe.bIsControlledByCutscene)
			return true;
		if (!QueueComp.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SanctuaryMedallionHydraDevToggles::Hydra::NoAttacks.IsEnabled())
			return;

		if (MioHighfiveComp.IsHighfiveJumping() || ZoeHighfiveComp.IsHighfiveJumping())
			return;

		switch (Manager.Phase)
		{
			case EMedallionPhase::Sidescroller1: Sidescroller1();
			break;
			case EMedallionPhase::Flying1: Flying1();
			break;
			case EMedallionPhase::Flying1Loop: Flying1Loop();
			break;
			case EMedallionPhase::Flying1LoopBack: Flying1LoopBack();
			break;
			case EMedallionPhase::Sidescroller2: Sidescroller2();
			break;
			case EMedallionPhase::Flying2: Flying2();
			break;
			case EMedallionPhase::Flying2Loop: Flying2Loop();
			break;
			case EMedallionPhase::Flying2LoopBack: Flying2LoopBack();
			break;
			case EMedallionPhase::Sidescroller3: Sidescroller3();
			break;
			case EMedallionPhase::Flying3: Flying3();
			break;
			case EMedallionPhase::Flying3Loop: Flying3Loop();
			break;
			case EMedallionPhase::Flying3LoopBack: Flying3LoopBack();
			break;
			case EMedallionPhase::Ballista1: Ballista1();
			break;
			case EMedallionPhase::BallistaNearBallista1: Ballista1Near();
			break;
			case EMedallionPhase::BallistaPlayersAiming1: Ballista1Aiming();
			break;
			case EMedallionPhase::BallistaArrowShot1: BallistaArrowShot();
			break;
			case EMedallionPhase::Ballista2: Ballista2();
			break;
			case EMedallionPhase::BallistaNearBallista2: Ballista2Near();
			break;
			case EMedallionPhase::BallistaPlayersAiming2: Ballista2Aiming();
			break;
			case EMedallionPhase::BallistaArrowShot2: BallistaArrowShot();
			break;
			case EMedallionPhase::Ballista3: Ballista3();
			break;
			case EMedallionPhase::BallistaNearBallista3: Ballista3Near();
			break;
			case EMedallionPhase::BallistaPlayersAiming3: Ballista3Aiming();
			break;
			case EMedallionPhase::BallistaArrowShot3: BallistaArrowShot();
			break;
			
			case EMedallionPhase::Merge1: Merge1();
			break;
			case EMedallionPhase::Merge2: Merge2();
			break;
			case EMedallionPhase::Merge3: Merge3();
			break;

			case EMedallionPhase::Strangle2:
			case EMedallionPhase::Strangle1:
			case EMedallionPhase::Strangle3:
			case EMedallionPhase::GloryKill1:
			case EMedallionPhase::GloryKill2:
			case EMedallionPhase::GloryKill3:
			case EMedallionPhase::FlyingExitReturn1:
			case EMedallionPhase::FlyingExitReturn2:
			case EMedallionPhase::Strangle1Sequence:
			case EMedallionPhase::Strangle2Sequence:
			case EMedallionPhase::Strangle3Sequence:
			case EMedallionPhase::Skydive:
			case EMedallionPhase::None:
			break;
		}
	}

	// ---------------------
	// Attack phases

	void Sidescroller1()
	{
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		RainAttack(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		RainAttack(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(5.0);
		// LaunchProjectileTriple(EMedallionHydra::MioRight, Game::Mio);
		// Idle(1.5);
		// LaunchProjectileTriple(EMedallionHydra::ZoeRight, Game::Zoe);
		// Idle(1.5);
		// ArcSprayAttack(EMedallionHydra::MioRight, Game::Mio);
		// Idle(3.0);
		// ArcSprayAttack(EMedallionHydra::ZoeLeft, Game::Zoe);
	}
	
	void Merge1()
	{
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(2.0);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
	}

	void Flying1()
	{
	}

	void Flying1Loop()
	{
	}

	void Flying1LoopBack()
	{
	}

	void Sidescroller2()
	{
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(1.5);
		RainAttack(EMedallionHydra::MioRight, Game::Mio);
		RainAttack(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(5.0);
		Idle(2.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioRight, Game::Mio);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(0.5);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		SidescrollerSpam(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		SidescrollerSpam(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(7.5);
	}

	void Merge2()
	{
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(2.0);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
	}

	void Flying2()
	{
		LaunchFlyingProjectile(EMedallionHydra::ZoeLeft, Game::Mio);
		Idle(0.5);
		LaunchFlyingProjectile(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.0);
		LaunchFlyingProjectile(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(1.0);
		LaunchFlyingProjectile(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.0);
		LaunchFlyingProjectile(EMedallionHydra::ZoeLeft, Game::Mio);
		Idle(1.0);
		LaunchFlyingProjectile(EMedallionHydra::MioBack, Game::Zoe);
		Idle(20.0);
	}

	void Flying2Loop()
	{
		Idle(1.5);
		LaunchFlyingProjectile(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(1.5);
		LaunchFlyingProjectile(EMedallionHydra::MioLeft, Game::Mio);
		Idle(10.0);
	}

	void Flying2LoopBack()
	{
		Idle(1.5);
		LaunchFlyingProjectile(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(10.0);
	}

	void Sidescroller3()
	{
		Idle(1.5);
		LaunchProjectileSplitting(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		LaunchProjectileSplitting(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSplitting(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSplitting(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSplitting(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		LaunchProjectileSplitting(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(0.5);
		ChaseLaser(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSplitting(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		//LaunchProjectileSplittingSetOffset(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		LaunchProjectileSplitting(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSplittingSetOffset(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		ChaseLaser(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		//LaunchProjectileSplitting(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		//LaunchProjectileSplitting(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSplittingSetOffset(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		LaunchProjectileSplittingSetOffset(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(0.5);
		//LaunchProjectileSplitting(EMedallionHydra::MioLeft, Game::Mio);
		Idle(1.5);
		//LaunchProjectileSplitting(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
		LaunchProjectileSplitting(EMedallionHydra::MioRight, Game::Mio);
		Idle(0.5);
		LaunchProjectileSplittingSetOffset(EMedallionHydra::ZoeLeft, Game::Zoe);
	}

	void Merge3()
	{
		Idle(1.5);
		LaunchProjectileSingle(EMedallionHydra::MioLeft, Game::Mio);
		Idle(2.0);
		LaunchProjectileSingle(EMedallionHydra::ZoeRight, Game::Zoe);
		Idle(0.5);
	}

	void Flying3()
	{
		Idle(2.0);
		FlyingSlashLaser(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(3.0);
		FlyingSlashLaser(EMedallionHydra::MioRight, Game::Mio);
		Idle(1.5);
		Idle(0.5);
		Idle(12.0);
	}

	void Flying3Loop()
	{
		Idle(2.0);
		FlyingSlashLaser(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(10.0);
	}

	void Flying3LoopBack()
	{
		Idle(1.0);
		FlyingSlashLaser(EMedallionHydra::MioRight, Game::Zoe);
		Idle(10.0);
	}

	void Ballista1()
	{
		Idle(1.0);
		BallistaProjectile(EMedallionHydra::MioLeft, Game::Mio);
		Idle(2.0);
		BallistaProjectile(EMedallionHydra::ZoeLeft, Game::Zoe);
		Idle(3.0);
		LaneLaser2(EMedallionHydra::MioRight);
		Idle(2.0);
		LaneLaser1(EMedallionHydra::MioLeft);
		Idle(1.0);
		LaneLaser3(EMedallionHydra::ZoeLeft);
		Idle(7.0);
	}

	void Ballista1Near()
	{
		Idle(2.0);
		BallistaProjectile(EMedallionHydra::MioLeft, Game::Mio);
		Idle(3.0);
		BallistaProjectile(EMedallionHydra::ZoeLeft, Game::Zoe);
	}

	void Ballista1Aiming()
	{
		Idle(0.6);
		LaneLaserAbove1(EMedallionHydra::MioRight);
		Idle(7.0);
	}

	void Ballista2()
	{
		Idle(0.5);
		WaveAttack();
		Idle(7.0);
		LaneLaser3(EMedallionHydra::ZoeLeft, 3.0);
		Idle(0.5);
		LaneLaser1(EMedallionHydra::MioRight, 3.0);
		Idle(6.5);
	}

	void Ballista2Near()
	{
		Idle(2.0);
		BallistaProjectile(EMedallionHydra::MioRight, Game::Mio);
		Idle(3.0);
		BallistaProjectile(EMedallionHydra::ZoeLeft, Game::Zoe);
	}

	void Ballista2Aiming()
	{
		Idle(0.5);
		LaneLaserAbove2(EMedallionHydra::MioRight);
		Idle(7.0);
	}

	void Ballista3()
	{
		Idle(0.5);
		MeteorAttack();
		Idle(5.0);
	}

	void Ballista3Near()
	{
		Idle(3.0);
		BallistaProjectile(EMedallionHydra::MioRight, Game::Mio);
		Idle(5.0);
		BallistaProjectile(EMedallionHydra::MioRight, Game::Zoe);
		Idle(2.0);
	}

	void Ballista3Aiming()
	{
		Idle(0.5);
		LaneLaserAbove3(EMedallionHydra::MioRight);
		Idle(7.0);
	}

	void BallistaArrowShot()
	{
	}

	// ---------
	// Attack parts

	void Idle(float Duration)
	{
		QueueComp.Idle(Duration);
	}

	void LaunchProjectileSingle(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::BasicProjectileSingle);
	}

	void LaunchProjectileTriple(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::BasicProjectileTripple);
	}

	void LaunchProjectileSplitting(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::SplittingProjectile);
	}

	void LaunchProjectileSplittingSetOffset(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::SplittingSetOffsetProjectile);
	}

	void LaunchProjectileSplittingTriple(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::SplittingProjectileTriple);
	}

	void LaunchProjectileSplittingQuad(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::SplittingProjectileQuad);
	}

	void LaunchFlyingProjectile(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::FlyingProjectile);
	}

	void ArcSprayAttack(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::ArcSpray);
	}

	void RainAttack(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::RainAttack);
	}

	void ChaseLaser(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::ChaseLaser);
	}

	void SlashLaser(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::SlashLaser);
	}

	void AboveProjectile(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::AboveProjectile);
	}

	void FlyingSlashLaser(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::FlyingSlashLaser);
	}

	void LaneLaser1(EMedallionHydra Hydra, float AttackDuration = 5.0)
	{
		QueueAttack(Hydra, Game::Mio, EMedallionHydraAttack::LaneLaser1, AttackDuration);
	}

	void LaneLaser2(EMedallionHydra Hydra, float AttackDuration = 5.0)
	{
		QueueAttack(Hydra, Game::Mio, EMedallionHydraAttack::LaneLaser2, AttackDuration);
	}

	void LaneLaser3(EMedallionHydra Hydra, float AttackDuration = 5.0)
	{
		QueueAttack(Hydra, Game::Mio, EMedallionHydraAttack::LaneLaser3, AttackDuration);
	}

	void LaneLaserAbove1(EMedallionHydra Hydra, float AttackDuration = 5.0)
	{
		QueueAttack(Hydra, Game::Mio, EMedallionHydraAttack::LaneLaserAbove1, AttackDuration);
	}

	void LaneLaserAbove2(EMedallionHydra Hydra, float AttackDuration = 5.0)
	{
		QueueAttack(Hydra, Game::Mio, EMedallionHydraAttack::LaneLaserAbove2, AttackDuration);
	}

	void LaneLaserAbove3(EMedallionHydra Hydra, float AttackDuration = 5.0)
	{
		QueueAttack(Hydra, Game::Mio, EMedallionHydraAttack::LaneLaserAbove3, AttackDuration);
	}

	void WaveAttack()
	{
		QueueAttack(EMedallionHydra::MioRight, Game::Mio, EMedallionHydraAttack::Wave);
	}

	void MeteorAttack()
	{
		QueueAttack(EMedallionHydra::MioRight, Game::Mio, EMedallionHydraAttack::Meteor);
	}

	void BallistaProjectile(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::BallistaProjectile);
	}

	void SidescrollerSpam(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer)
	{
		QueueAttack(Hydra, TargetPlayer, EMedallionHydraAttack::SidescrollerSpam);
	}

	private void QueueAttack(EMedallionHydra Hydra, AHazePlayerCharacter TargetPlayer, EMedallionHydraAttack Attack, float AttackDuration = -1.0)
	{
		FSanctuaryMedallionHydraParams ParamsParams;
		ParamsParams.HydraType = Hydra;
		ParamsParams.TargetPlayer = TargetPlayer;
		ParamsParams.Attack = Attack;
		ParamsParams.AttackDuration = AttackDuration;

		FSanctuaryMedallionHydraResolveAttackActionParams Params;
		Params.HydraActions.Add(ParamsParams);

		QueueComp.Capability(USanctuaryMedallionHydraResolveAttackCapability, Params);
	}
};