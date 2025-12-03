struct FBattlefieldHoverboardTrickComboActivationParams
{
	EBattlefieldHoverboardTrickType CurrentTrickType;
}

class UBattlefieldHoverboardTrickComboCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrick);
	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 110;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickComponent TrickComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UPlayerMovementComponent MoveComp;

	UBattlefieldHoverboardTrickSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardTrickComboActivationParams& Params) const
	{
		if(!HoverboardComp.IsOn())
			return false;

		if(TrickComp.CurrentTrick.IsSet())
		{
			Params.CurrentTrickType = TrickComp.CurrentTrick.Value.Type;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround()
		&& !GrindComp.bIsOnGrind && !GrindComp.bIsJumpingWhileGrinding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardTrickComboActivationParams Params)
	{
		FBattlefieldHoverboardTrickCombo TrickCombo;
		TrickCombo.ComboPoints = 0.0;
		TrickCombo.PreviousTrickType = Params.CurrentTrickType;
		TrickCombo.ComboMultiplier = 1;
		TrickCombo.TrickCount = 1;
		TrickComp.CurrentTrickCombo.Set(TrickCombo);
		TrickComp.AwardTrickPoints();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!TrickComp.bTrickFailed)
		{
			UBattlefieldHoverboardEffectHandler::Trigger_OnSuccessfulLand(HoverboardComp.Hoverboard);
		}
		
		TrickComp.LastTimeTrickComboCompleted = Time::GameTimeSeconds;
		TrickComp.CurrentTrickCombo.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		if(!TrickComp.CurrentTrickCombo.IsSet())
			return;
		auto CurrentCombo = TrickComp.CurrentTrickCombo.Value;

		TEMPORAL_LOG(Player, "Tricks").Page("Combo")
			.Value("Previous Type", CurrentCombo.PreviousTrickType)
			.Value("Points", CurrentCombo.ComboPoints)
		;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!TrickComp.CurrentTrick.IsSet())
		{
			auto CurrentTrick = TrickComp.CurrentTrickCombo.Value.PreviousTrickType;
			if(CurrentTrick == EBattlefieldHoverboardTrickType::Grind || CurrentTrick == EBattlefieldHoverboardTrickType::WallRun)
			{
				TrickComp.CurrentTrickCombo.Value.ComboPoints = Math::CeilToInt(TrickComp.CurrentTrickCombo.Value.ComboPoints / 5.0) * 5;
			}

			return;
		}	
		auto CurrentTrick = TrickComp.CurrentTrick.Value;

		if(!TrickComp.CurrentTrickCombo.IsSet())
			return;
		auto& CurrentCombo = TrickComp.CurrentTrickCombo.Value;

		if(CurrentTrick.Type == EBattlefieldHoverboardTrickType::Grind)
		{
			float GrindPointsGained = Settings.GrindTrickPointsPerSecond * DeltaTime;
			CurrentCombo.ComboPoints += GrindPointsGained;
		}
		else if(CurrentTrick.Type == EBattlefieldHoverboardTrickType::WallRun)
		{
			float WallRunPointsGained = Settings.WallRunTrickPointsPerSecond * DeltaTime;
			CurrentCombo.ComboPoints += WallRunPointsGained;
		}
	}
};