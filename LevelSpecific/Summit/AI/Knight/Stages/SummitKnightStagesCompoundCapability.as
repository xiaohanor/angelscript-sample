class USummitKnightPathStartArea1CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::PathStartArena;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerHealthSettings::SetRespawnTimer(Player, 1.0, this);
			UPlayerHealthSettings::SetRegenerationDelay(Player, 20, this);
			UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Player, false, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearSettingsByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightMetalWallBehaviour())
				.Then(USummitKnightMetalWallBehaviour())
				.Then(USummitKnightCrystalWallBehaviour(1.0, 1.5))
				.Then(USummitKnightCrystalWallBehaviour(1.0, 1.5))
			;
	}
}

class USummitKnightPathEndCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::PathEndArena;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerHealthSettings::SetRespawnTimer(Player, 1.0, this);
			UPlayerHealthSettings::SetRegenerationDelay(Player, 20, this);
			UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Player, false, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearSettingsByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightPathEndSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0))
			;
	}
}

class USummitKnightFinalArenaStartCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaStart;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightSpinningSlashBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightFinalSmashBehaviour()) 
				.Then(USummitKnightPauseBehaviour(3.0))
				.Then(USummitKnightSetRoundCapability(2))
			;
	}
}

class USummitKnightFinalArenaStartRepeat1CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaStart;
	default Round = 2;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightSpinningSlashBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightFinalSmashBehaviour()) 
				.Then(USummitKnightPauseBehaviour(2.0))
				.Then(USummitKnightSetRoundCapability(3))
			;
	}
}

class USummitKnightFinalArenaStartRepeat2CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaStart;
	default Round = 3;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightFinalSmashBehaviour()) 
				.Then(USummitKnightPauseBehaviour(2.0))
				.Then(USummitKnightSetRoundCapability(4))
			;
	}
}

class USummitKnightFinalArenaStartRepeat3CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaStart;
	default Round = 4;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightShockwaveBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightFinalSmashBehaviour()) 
				.Then(USummitKnightPauseBehaviour(2.0))
				.Then(USummitKnightSetRoundCapability(2))
			;
	}
}



class USummitKnightFinalArenaEndCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaEnd;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightShockwaveBehaviour(0.8, 1.5))
				.Then(USummitKnightCrystalWallBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightSpinningSlashBehaviour(1.0, 1.5))
				.Then(USummitKnightCrystalWallBehaviour())
				.Then(USummitKnightFinalRailSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(3.0))
				.Then(USummitKnightSetRoundCapability(2))
			;
	}
}

class USummitKnightFinalArenaEndRepeat1CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaEnd;
	default Round = 2;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightCrystalWallBehaviour())
				.Then(USummitKnightFinalRailSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(2.0))
				.Then(USummitKnightSetRoundCapability(3))
			;
	}
}

class USummitKnightFinalArenaEndRepeat2CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaEnd;
	default Round = 3;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightCrystalWallBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightShockwaveBehaviour(0.8, 1.5))
				.Then(USummitKnightFinalRailSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(2.0))
				.Then(USummitKnightSetRoundCapability(4))
			;
	}
}

class USummitKnightFinalArenaEndRepeat3CompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::FinalArenaEnd;
	default Round = 4;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightSpinningSlashBehaviour(1.0, 1.5))
				.Then(USummitKnightFinalRailSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(2.0))
				.Then(USummitKnightSetRoundCapability(2))
			;
	}
}


UCLASS(Abstract)
class USummitKnightStagesCompoundCapability : UHazeCompoundCapability
{
	ESummitKnightPhase Phase = ESummitKnightPhase::None;
	uint8 Round = 0;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	USummitKnightStageComponent StageComp;
	USummitKnightComponent KnightComp;
	USummitKnightSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StageComp = USummitKnightStageComponent::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StageComp.Phase != Phase)
			return false;
		if (StageComp.Round != Round)
			return false;
		if (KnightComp.Arena == nullptr)
			return false;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StageComp.Phase != Phase)
			return true;
		if (StageComp.Round != Round)
			return true;
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		// Dummy
		return UHazeCompoundRunAll();
	}	
}

class USummitKnightTestHomingFireballsCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightHomingFireballsBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::PathStartArena))
			;
	}
}
class USummitKnightTestRotatingCrystalCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 2;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightRotatingCrystalBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::PathStartArena))
			;
	}
}

class USummitKnightTestAreaDenialFireballsCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 3;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightAreaDenialFireballBehaviour())
				.Then(USummitKnightPauseBehaviour(7.0, ESummitKnightPhase::PathStartArena))
			;
	}
}

class USummitKnightTestCrystalWallCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 4;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightCrystalWallBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestFlailSmashCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 5;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightFlailSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestShockwaveCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 6;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightShockwaveBehaviour())
				.Then(USummitKnightPauseBehaviour(2.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestSpinningSlashCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 7;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSpinningSlashBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestGenericAttacksCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 8;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSingleSlashBehaviour())
				.Then(USummitKnightSingleSlashBehaviour())
			;
	}
}

class USummitKnightTestCrystalTrailCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 9;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightCrystalTrailBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::PathStartArena))
			;
	}
}

class USummitKnightTestFinalSmashCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 10;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightFinalSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestFinalRailSmashCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 11;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightFinalRailSmashBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestSummonCrittersCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 12;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightSummonCrittersBehaviour())
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightPauseBehaviour(5.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}

class USummitKnightTestMetalWallCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::Test;
	default Round = 13;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
				.Then(USummitKnightStopSummoningBehaviour())
				.Then(USummitKnightMetalWallBehaviour())
				.Then(USummitKnightPauseBehaviour(1.0, ESummitKnightPhase::FinalArenaStart))
			;
	}
}



