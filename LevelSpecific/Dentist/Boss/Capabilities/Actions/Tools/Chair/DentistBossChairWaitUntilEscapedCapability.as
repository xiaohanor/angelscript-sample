struct FDentistBossChairWaitUntilEscapedDeactivationParams
{
	AHazePlayerCharacter EscapedPlayer;
	bool bDeactivatedNaturally = false;
}

class UDentistBossChairWaitUntilEscapedCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;
	ADentistBossToolChair MioChair;
	ADentistBossToolChair ZoeChair;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		MioChair = Dentist.MioChair;
		ZoeChair = Dentist.ZoeChair;
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistBossChairWaitUntilEscapedDeactivationParams& Params) const
	{
		if(!MioChair.RestrainedPlayer.IsSet())
		{
			Params.EscapedPlayer = Game::Mio;
			Params.bDeactivatedNaturally = true;
			return true;
		}
		if(!ZoeChair.RestrainedPlayer.IsSet())
		{
			Params.EscapedPlayer = Game::Zoe;
			Params.bDeactivatedNaturally = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistBossChairWaitUntilEscapedDeactivationParams Params)
	{
		if(Params.bDeactivatedNaturally)
		{
			TargetComp.DrillTargets.Add(Params.EscapedPlayer.OtherPlayer);
			if(Params.EscapedPlayer.IsMio())
				Dentist.bLeftPlayerEscapedChair = true;
			else
				Dentist.bRightPlayerEscapedChair = true;
		}
	}
};