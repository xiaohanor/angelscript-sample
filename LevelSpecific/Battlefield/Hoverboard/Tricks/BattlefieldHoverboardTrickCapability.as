struct FBattlefieldHoverboardTrickActivationParams
{
	EBattlefieldHoverboardTrickType ActivatedTrickType;
	UBattlefieldHoverboardTrickAnimationData ActivatedTrickAnimData;
	int ActivatedTrickIndex = 0;
}

struct FBattlefieldHoverboardTrickDeactivationParams
{
	bool bDeactivatedByTouchingGround = false;
	bool bWithinFailureWindow = false;
}

class UBattlefieldHoverboardTrickCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrick);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickComponent TrickComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardWallRunComponent WallRunComp;
	UBattlefieldHoverboardLoopComponent LoopComp;
	UPlayerMovementComponent MoveComp;

	const float GraceTimeDuration = 0.2;

	float LastTimeInputX = -MAX_flt;
	float LastTimeInputY = -MAX_flt;
	float LastTimeInputB = -MAX_flt;

	FBattlefieldHoverboardTrickActivationParams CurrentlyActiveParams;
	FBattlefieldHoverboardTrickActivationParams PreviouslyActiveParams;

	UBattlefieldHoverboardTrickSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		WallRunComp = UBattlefieldHoverboardWallRunComponent::Get(Player);
		LoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardTrickActivationParams& Params) const
	{
		if(!HoverboardComp.IsOn())
			return false;
		
		if(!BattlefieldDevToggles::FreezeMovement.IsEnabled() && MoveComp.IsOnAnyGround())
			return false;

		if(TrickComp.CurrentTrick.IsSet())
			return false;

		// if(GrindComp.bIsJumpingToGrind)
		// 	return false;

		// if(GrindComp.bIsJumpingBetweenGrinds)
		// 	return false;

		// if(GrindComp.bIsJumpingWhileGrinding)
		// 	return false;

		if(LoopComp.bIsInLoop)
			return false;

		if(GrindComp.IsGrinding())
		{
			if(!GrindComp.bIsJumpingWhileGrinding)
			{
				Params.ActivatedTrickType = EBattlefieldHoverboardTrickType::Grind;
				return true;
			}
		}

		if(WallRunComp.HasActiveWallRun())
		{
			Params.ActivatedTrickType = EBattlefieldHoverboardTrickType::WallRun;
			return true;
		}


		// if(!TrickComp.bIsFarEnoughFromGroundToDoTrick)
		// 	return false;

		if(WasActionStartedDuringTime(ActionNames::MovementDash, GraceTimeDuration)
		|| WasActionStartedDuringTime(ActionNames::Interaction, GraceTimeDuration)
		|| WasActionStartedDuringTime(ActionNames::Cancel, GraceTimeDuration))
		{
			const float TimeSinceXInput = Time::GetGameTimeSince(LastTimeInputX);
			const float TimeSinceYInput = Time::GetGameTimeSince(LastTimeInputY);
			const float TimeSinceBInput = Time::GetGameTimeSince(LastTimeInputB);

			EBattlefieldHoverboardTrickType TrickType;
			if(TimeSinceXInput < TimeSinceYInput
			&& TimeSinceXInput < TimeSinceBInput)
				TrickType = EBattlefieldHoverboardTrickType::X;
			else if(TimeSinceYInput < TimeSinceXInput
			&& TimeSinceYInput < TimeSinceBInput)
				TrickType = EBattlefieldHoverboardTrickType::Y;
			else
				TrickType = EBattlefieldHoverboardTrickType::B;

			Params.ActivatedTrickType = TrickType;
			SetRandomTrickAnimData(Params);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBattlefieldHoverboardTrickDeactivationParams& Params) const
	{
		if(CurrentlyActiveParams.ActivatedTrickType == EBattlefieldHoverboardTrickType::Grind)
		{
			if(!GrindComp.bIsOnGrind)
				return true;

			if(GrindComp.bIsJumpingWhileGrinding)
				return true;
		}
		else if(CurrentlyActiveParams.ActivatedTrickType == EBattlefieldHoverboardTrickType::WallRun)
		{
			if(!WallRunComp.HasActiveWallRun())
				return true;
		}
		else
		{
			if(ActiveDuration > CurrentlyActiveParams.ActivatedTrickAnimData.DurationBeforeTrickCompleted)
				return true;

			if(MoveComp.IsOnAnyGround() || GrindComp.bIsOnGrind)
			{
				Params.bDeactivatedByTouchingGround = true;

				if(GrindComp.bIsOnGrind) //Kinder range if you are on a grind
				{
					if(CurrentlyActiveParams.ActivatedTrickType == EBattlefieldHoverboardTrickType::X) //cannot fail short trick
						Params.bWithinFailureWindow = false;
					else
					{
						FHazeRange ModifiedRange;
						ModifiedRange.Min = CurrentlyActiveParams.ActivatedTrickAnimData.FailWindow.Min * 0.8;
						ModifiedRange.Max = CurrentlyActiveParams.ActivatedTrickAnimData.FailWindow.Max * 1.2;
						Params.bWithinFailureWindow = CurrentlyActiveParams.ActivatedTrickAnimData.FailWindow.IsInRange(ActiveDuration);
					}
				}
				else
					Params.bWithinFailureWindow = CurrentlyActiveParams.ActivatedTrickAnimData.FailWindow.IsInRange(ActiveDuration);

				return true;
			}
		}


		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardTrickActivationParams Params)
	{
		bool bIncreaseMult = false;
		TrickComp.bTrickFailed = false;
		CurrentlyActiveParams = Params;

		FBattlefieldHoverboardTrick NewTrick;
		NewTrick.Type = Params.ActivatedTrickType;
		TrickComp.CurrentTrick.Set(NewTrick);
		TrickComp.OnNewTrick.Broadcast(NewTrick.Type);
		if(Params.ActivatedTrickType != EBattlefieldHoverboardTrickType::Grind)
		{
			Player.SetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickType, int(Params.ActivatedTrickType));
			Player.SetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickIndex, Params.ActivatedTrickIndex);
			Player.SetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered, true);
		}

		TrickComp.bHasAwardedPointsForCurrentTrick = false;

		if(TrickComp.CurrentTrickCombo.IsSet())
		{
			if(Params.ActivatedTrickType != TrickComp.CurrentTrickCombo.Value.PreviousTrickType && Params.ActivatedTrickType != EBattlefieldHoverboardTrickType::Grind)
			{
				if((!GrindComp.IsGrinding() && !GrindComp.bIsJumpingWhileGrinding) || GrindComp.bIsJumpingToGrind)
				{
					bIncreaseMult = true;
					TrickComp.IncreaseTrickMultiplier(Settings.TrickMultiplierIncreasePerDifferentTrick);
				}
			}
			TrickComp.CurrentTrickCombo.Value.PreviousTrickType = Params.ActivatedTrickType;
			TrickComp.CurrentTrickCombo.Value.TrickCount++;
			TrickComp.AwardTrickPoints();
		}

		FBattlefieldHoverboardTrickParams EffectParams;
		EffectParams.TrickType = Params.ActivatedTrickType;
		EffectParams.bIncreaseMult = bIncreaseMult;
		UBattlefieldHoverboardEffectHandler::Trigger_OnNewTrick(HoverboardComp.Hoverboard, EffectParams);
		
		Player.PlayForceFeedback(HoverboardComp.TrickRumble, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBattlefieldHoverboardTrickDeactivationParams Params)
	{
		if(Params.bDeactivatedByTouchingGround)
			Player.SetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickLandBeforeFinished, true);
		if(Params.bWithinFailureWindow)
		{
			Player.SetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickFailed, true);
			TrickComp.FailTrick();
			UBattlefieldHoverboardEffectHandler::Trigger_OnTrickFailed(HoverboardComp.Hoverboard);
		}
		//else if(CurrentlyActiveParams.ActivatedTrickType != EBattlefieldHoverboardTrickType::Grind)
		//	TrickComp.AwardTrickPoints();
			
		TrickComp.CurrentTrick.Reset();

		PreviouslyActiveParams = CurrentlyActiveParams; 
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(WasActionStarted(ActionNames::MovementDash))
			LastTimeInputX = Time::GameTimeSeconds;
		if(WasActionStarted(ActionNames::Interaction))
			LastTimeInputY = Time::GameTimeSeconds;
		if(WasActionStarted(ActionNames::Cancel))
			LastTimeInputB = Time::GameTimeSeconds;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		if(!TrickComp.CurrentTrick.IsSet())
			return;
		auto CurrentTrick = TrickComp.CurrentTrick.Value;
		auto TempLogPage = TEMPORAL_LOG(Player, "Tricks").Page("Current Trick");

		TempLogPage
			.Value("Type", CurrentTrick.Type)
		;

		if(CurrentTrick.AnimData != nullptr)
		{
			TempLogPage
				.Value("Duration Before Trick Completed", CurrentTrick.AnimData.DurationBeforeTrickCompleted)
				.Value("Fail Window", CurrentTrick.AnimData.FailWindow)
			;
		}
	}
	
	void SetRandomTrickAnimData(FBattlefieldHoverboardTrickActivationParams& Params) const
	{
		UBattlefieldHoverboardTrickAnimationData AnimData;
		UBattlefieldHoverboardTrickList TrickList;
		if(Params.ActivatedTrickType == EBattlefieldHoverboardTrickType::X)
			TrickList = HoverboardComp.XTrickList;
		else if(Params.ActivatedTrickType == EBattlefieldHoverboardTrickType::Y)
			TrickList = HoverboardComp.YTrickList;
		else
			TrickList = HoverboardComp.BTrickList;

		auto TrickArray = TrickList.AnimData;
		if(PreviouslyActiveParams.ActivatedTrickType == Params.ActivatedTrickType)
			TrickArray.Remove(PreviouslyActiveParams.ActivatedTrickAnimData);

		int Index = Math::RandRange(0, TrickArray.Num() - 1);

		AnimData = TrickArray[Index];

		Params.ActivatedTrickIndex = TrickList.AnimData.FindIndex(AnimData);;
		Params.ActivatedTrickAnimData = AnimData;
	}
};