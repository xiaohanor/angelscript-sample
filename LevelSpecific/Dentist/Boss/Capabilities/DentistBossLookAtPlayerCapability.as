class UDentistBossLookAtPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;
	UDentistBossSettings Settings;
	FHazeAcceleratedVector AccLookTarget;

	float TimeLastChangedFallbackTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TargetComp.bOverrideLooking)
			return false;

		if(!Dentist.LookAtEnabled.Get())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TargetComp.bOverrideLooking)
			return true;

		if(!Dentist.LookAtEnabled.Get())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccLookTarget.SnapTo(TargetComp.LookTargetLocation);
		auto FallbackTargetPlayer = GetRandomValidPlayer();
		if(FallbackTargetPlayer != nullptr)
			SetNewFallbackTarget(FallbackTargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccLookTarget.AccelerateTo(GetLookTargetLocation(), Settings.LookDuration, DeltaTime);
		TargetComp.LookAtTarget(AccLookTarget.Value);
		
		auto Target = TargetComp.Target.Get();
		bool bTargetIsValidForLook = IsValidLookAtTarget(Target);
		if(Time::GetGameTimeSince(TimeLastChangedFallbackTarget) > Settings.FallbackTargetSwapDelay
		|| !bTargetIsValidForLook)
		{
			if(Target == nullptr)
			{
				auto ValidPlayer = GetRandomValidPlayer();
				if(ValidPlayer == nullptr)
					return;
				else
				{
					SetNewFallbackTarget(ValidPlayer);
					return;
				}
			}

			bool bOtherPlayerIsValidForLook = IsValidLookAtTarget(Target.OtherPlayer);
			if(!bTargetIsValidForLook
			&& !bOtherPlayerIsValidForLook)
			{
				ClearFallbackTarget();
			}

			if(bOtherPlayerIsValidForLook)
				SetNewFallbackTarget(TargetComp.Target.Get().OtherPlayer);
		}
	}

	FVector GetLookTargetLocation() const
	{
		if(TargetComp.Target.Get() == nullptr
		|| TargetComp.Target.Get().IsPlayerDeadOrRespawning()
		|| !TargetComp.IsOnCake[TargetComp.Target.Get()])
			return Dentist.Cake.ActorLocation;

		return TargetComp.Target.Get().ActorCenterLocation;
	}

	AHazePlayerCharacter GetRandomValidPlayer()
	{
		int Rand = Math::RandRange(0, 1);
		auto Player = Rand == 0 ? Game::Zoe : Game::Mio;
		if(IsValidLookAtTarget(Player))
			return Player;
		else if(IsValidLookAtTarget(Player.OtherPlayer))
			return Player.OtherPlayer;
		else
			return nullptr;
	}
	
	void SetNewFallbackTarget(AHazePlayerCharacter NewTarget)
	{
		TargetComp.Target.SetDefaultValue(NewTarget);
		TimeLastChangedFallbackTarget = Time::GameTimeSeconds;
	}
	
	void ClearFallbackTarget()
	{
		TargetComp.Target.SetDefaultValue(nullptr);
	}

	bool IsValidLookAtTarget(AHazePlayerCharacter Target)
	{
		if(Target == nullptr)
			return false;

		if(Target.IsPlayerDeadOrRespawning())
			return false;

		if(!TargetComp.IsOnCake[Target])
			return false;

		return true;
	}
};