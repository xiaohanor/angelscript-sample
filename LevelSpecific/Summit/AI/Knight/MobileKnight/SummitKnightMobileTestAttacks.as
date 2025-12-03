namespace KnightDevtoggles
{
	const FHazeDevToggleCategory KnightCategory = FHazeDevToggleCategory(n"Knight");
	const FHazeDevToggleGroup TestBehaviour = FHazeDevToggleGroup(KnightCategory, n"Test Behaviour", "Test a single knight behaviour at a time.");
	const FHazeDevToggleOption NoTest = FHazeDevToggleOption(TestBehaviour, n"No testing", true);
	const FHazeDevToggleOption TestSlamAttack = FHazeDevToggleOption(TestBehaviour, n"Slam Attack");
	const FHazeDevToggleOption TestSwoopAcrossArena = FHazeDevToggleOption(TestBehaviour, n"Swoop Across Arena");
	const FHazeDevToggleOption TestSmashGround = FHazeDevToggleOption(TestBehaviour, n"Smash Ground Attack");
	const FHazeDevToggleOption TestSingleSlash = FHazeDevToggleOption(TestBehaviour, n"Slash Once");
	const FHazeDevToggleOption TestDualSlash = FHazeDevToggleOption(TestBehaviour, n"Slash Twice");
	const FHazeDevToggleOption TestSpinningSlashShockwave = FHazeDevToggleOption(TestBehaviour, n"Spinning Slash Shockwave");
	const FHazeDevToggleOption TestHomingFireballs = FHazeDevToggleOption(TestBehaviour, n"Homing Fireballs");
	const FHazeDevToggleOption TestTrackingFlames = FHazeDevToggleOption(TestBehaviour, n"Tracking Flames");
	const FHazeDevToggleOption TestSummonCritters = FHazeDevToggleOption(TestBehaviour, n"Summon Critters");
	const FHazeDevToggleOption TestLargeAreaStrike = FHazeDevToggleOption(TestBehaviour, n"Large Area Strike");
	const FHazeDevToggleOption TestHurtReaction = FHazeDevToggleOption(TestBehaviour, n"Hurt Reaction");
	const FHazeDevToggleOption TestCrystalCage = FHazeDevToggleOption(TestBehaviour, n"CC (Test)");
}

class USummitKnightMobileTestCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 0;

	bool bRestart = false;

	ESummitKnightPhase PrevPhase = ESummitKnightPhase::MobileStart;
	uint8 PrevRound = 0;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightDevtoggles::TestBehaviour.MakeVisible();
		KnightDevtoggles::TestBehaviour.BindOnChanged(this, n"OnTestBehaviourChanged");
		OnTestBehaviourChanged(KnightDevtoggles::TestBehaviour.GetCurrentChosenOption());		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (bRestart)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bRestart = false;
	}

	UFUNCTION()
	private void OnTestBehaviourChanged(FName NewState)
	{
		if (KnightDevtoggles::NoTest.IsEnabled())
		{
			if (StageComp.Phase == ESummitKnightPhase::Test)
				StageComp.SetPhase(PrevPhase, PrevRound);
			return;
		}
		
		if (StageComp.Phase != ESummitKnightPhase::Test)
		{
			PrevPhase = StageComp.Phase;
			PrevRound = StageComp.Round;
		}
		StageComp.SetPhase(ESummitKnightPhase::Test, 0);
		bRestart = true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(USummitKnightTestSlamAttackBehaviour())
					.Try(USummitKnightTestSwoopAcrossArenaBehaviour())
					.Try(USummitKnightTestSmashGroundBehaviour())
					.Try(USummitKnightTestSingleSlashBehaviour())
					.Try(USummitKnightTestDualSlashBehaviour())
					.Try(USummitKnightTestSpinningSlashShockwaveBehaviour())
					.Try(USummitKnightTestHomingFireballsBehaviour())
					.Try(USummitKnightTestLargeAreaStrikeBehaviour())
					.Try(USummitKnightTestHurtReactionBehaviour())
					.Try(USummitKnightTestTrackingFlamesBehaviour())
					.Try(USummitKnightTestSummonCrittersBehaviour())
					.Try(USummitKnightTestCrystalCageBehaviour())
				)
				.Add(USummitKnightTestCircleArenaBehaviour())
			;
	}
}

class USummitKnightTestSlamAttackBehaviour : USummitKnightMobileStartSlamAttackBehaviour
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		bSpawnObstacles = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FKnightSlamAttackParams& OutParams) const
	{
		if (!KnightDevtoggles::TestSlamAttack.IsEnabled())
			return false;
		if (!Cooldown.IsOver()) // Super will normally not allow activation
			return false;
		OutParams.bStartWithHurtReaction = (Time::GetGameTimeSince(KnightComp.LastStunnedTime) > 0.5);	
		OutParams.ObstacleParams = GetObstacleSpawnParameters();	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FKnightSlamDeactivationParams Params)
	{
		Super::OnDeactivated(Params);
		Cooldown.Set(2.0);

		if (Owner.ActorLocation.IsWithinDist2D(KnightComp.Arena.Center, 2000.0))
			Owner.TeleportActor(KnightComp.Arena.Center - Owner.ActorForwardVector * KnightComp.Arena.Radius, FRotator(0.0, Math::RandRange(-180.0, 180.0), 0.0), this);
	}
}

class USummitKnightTestSwoopAcrossArenaBehaviour : USummitKnightSwoopAcrossArenaBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FKnightSwoopAcrossArenaParams& OutParams) const
	{
		if (!KnightDevtoggles::TestSwoopAcrossArena.IsEnabled())
			return false;
		return Super::ShouldActivate(OutParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestSmashGroundBehaviour : USummitKnightSmashGroundBehaviour
{
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!KnightDevtoggles::TestSmashGround.IsEnabled())
			return;
		if (TargetComp.HasValidTarget())
			return;
		if (TargetComp.IsValidTarget(Game::Mio))
			TargetComp.SetTarget(Game::Mio);
		else
			TargetComp.SetTarget(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestSmashGround.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestSingleSlashBehaviour : USummitKnightSingleSlashBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestSingleSlash.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}
}

class USummitKnightTestDualSlashBehaviour : USummitKnightDualSlashBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestDualSlash.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}
}

class USummitKnightTestSpinningSlashShockwaveBehaviour : USummitKnightSpinningSlashBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestSpinningSlashShockwave.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestHomingFireballsBehaviour : USummitKnightHomingFireballsBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestHomingFireballs.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestTrackingFlamesBehaviour : USummitKnightCrystalTrailBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestTrackingFlames.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestSummonCrittersBehaviour : USummitKnightSummonCrittersBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestSummonCritters.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestLargeAreaStrikeBehaviour : USummitKnightLargeAreaStrikeBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestLargeAreaStrike.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestCrystalCageBehaviour : USummitKnightCrystalCageBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestCrystalCage.IsEnabled())
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(30.0);
	}
}

class USummitKnightTestHurtReactionBehaviour : USummitKnightMobileHurtReactionBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KnightDevtoggles::TestHurtReaction.IsEnabled())
			return false;
		if (!Cooldown.IsOver()) // Super will normally not allow activation
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(2.0);
	}
}

class USummitKnightTestCircleArenaBehaviour : USummitKnightCircleArenaBehaviour
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!KnightDevtoggles::TestSummonCritters.IsEnabled() && 
			!KnightDevtoggles::TestLargeAreaStrike.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!KnightDevtoggles::TestSummonCritters.IsEnabled() && 
			!KnightDevtoggles::TestLargeAreaStrike.IsEnabled())
			return true;
		return false;
	}
}
