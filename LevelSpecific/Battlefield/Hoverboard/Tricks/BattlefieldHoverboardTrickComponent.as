enum EBattlefieldHoverboardTrickType
{
	X,			// 0
	Y,			// 1
	B,			// 2
	Grind,		// 3
	WallRun, 	// 4
	MAX			// 5
}

struct FBattlefieldHoverboardTrick
{
	EBattlefieldHoverboardTrickType Type;
	UBattlefieldHoverboardTrickAnimationData AnimData;
	bool bFailed = false;
}

struct FBattlefieldHoverboardTrickCombo
{
	EBattlefieldHoverboardTrickType PreviousTrickType;
	float ComboPoints = 0;
	float ComboMultiplier = 1;
	int TrickCount = 0;
}

event void FBattlefieldOnNewTrickEvent(EBattlefieldHoverboardTrickType Trick);
event void FBattlefieldOnTrickFailedEvent();

class UBattlefieldHoverboardTrickComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickSettings Settings;

	TOptional<FBattlefieldHoverboardTrick> CurrentTrick;
	TOptional<FBattlefieldHoverboardTrickCombo> CurrentTrickCombo;

	FBattlefieldOnNewTrickEvent OnNewTrick;
	FBattlefieldOnTrickFailedEvent OnTrickFailed;

	TArray<ABattlefieldHoverboardTrickVolume> IsInVolume;
	TArray<ABattlefieldHoverboardRampJumpVolume> JumpVolumesInsideOf;

	bool bHasPerformedTrickSinceLanding = false;
	bool bHasAwardedPointsForCurrentTrick = false;
	bool bIsFarEnoughFromGroundToDoTrick = false;
	// bool bTrickWasCompleted = false;
	bool bTrickFailed = false;

	bool bIsWaitingAtExit = false;

	float CurrentTotalTrickPoints = 0.0;
	float LastTimeTrickComboCompleted = -MAX_flt;

	bool bCanRunTutorial = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);

		CurrentTotalTrickPoints = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("CurrentTotalTrickPoints", CurrentTotalTrickPoints)
		;
	}

	void FailTrick()
	{
		if(CurrentTrick.IsSet())
			bTrickFailed = true;

		if(CurrentTrickCombo.IsSet())
		{
			CurrentTrickCombo.Value.ComboPoints = 0;
			CurrentTrickCombo.Value.ComboMultiplier = 1;
		}

		OnTrickFailed.Broadcast();
	}

	ABattlefieldHoverboardRampJumpVolume GetLatestRampJumpVolume()
	{
		return JumpVolumesInsideOf.Num() == 0 ? JumpVolumesInsideOf[0] : JumpVolumesInsideOf[JumpVolumesInsideOf.Num() - 1]; 
	}

	bool IsInsideJumpVolume() const
	{
		return JumpVolumesInsideOf.Num() > 0;
	}

	bool IsInsideTrickVolume() const
	{
		return IsInVolume.Num() > 0;
	}

	bool HasAutoTrick() const
	{
		if (IsInVolume.Num() == 0)
			return false;
		
		for (ABattlefieldHoverboardTrickVolume Volume : IsInVolume)
		{
			if (Volume.bAutoTrick)
				return true;
		}

		return false;
	}

	void StoreTrickBoost()
	{
		bHasPerformedTrickSinceLanding = true;

		if(HoverboardComp == nullptr)
			HoverboardComp = UBattlefieldHoverboardComponent::Get(Owner);
		
		UBattlefieldHoverboardEffectHandler::Trigger_OnTrickBoostStored(HoverboardComp.Hoverboard);
	}

	UFUNCTION(DevFunction)
	void DevIncreaseScore()
	{
		if(CurrentTotalTrickPoints == 0)
			CurrentTotalTrickPoints = 1;
		
		CurrentTotalTrickPoints *= 10;
	}

	void AwardTrickPoints()
	{
		if(bHasAwardedPointsForCurrentTrick)
			return;

		int CurrentTrickPoints = 0;
		if(CurrentTrick.IsSet())
		{
			if(CurrentTrick.Value.bFailed)
				return;			

			switch(CurrentTrick.Value.Type)
			{
				case EBattlefieldHoverboardTrickType::X:
					CurrentTrickPoints = Settings.XTrickPointAmount;
					break;
				case EBattlefieldHoverboardTrickType::Y:
					CurrentTrickPoints = Settings.YTrickPointAmount;
					break;
				case EBattlefieldHoverboardTrickType::B:
					CurrentTrickPoints = Settings.BTrickPointAmount;
					break;
				default: // ¯\_(ツ)_/¯
					break;
			}
		}
		else
			devError("Tried to award point, but no current trick type was set");

		// Print(f"{CurrentTrickPoints}!", 1.0);
		if(CurrentTrickCombo.IsSet())
			CurrentTrickCombo.Value.ComboPoints += CurrentTrickPoints;
		bHasAwardedPointsForCurrentTrick = true;
	}

	void SaveTrickPoints()
	{
		if(Save::CanAccessProfileData())
		{
			if(Player.IsMio())
				Save::ModifyPersistentProfileCounter(n"TrickPointsMio", Math::RoundToInt(CurrentTotalTrickPoints));
			else
				Save::ModifyPersistentProfileCounter(n"TrickPointsZoe", Math::RoundToInt(CurrentTotalTrickPoints));
		}
	}

	void LoadTrickPoints()
	{
		if(Player.IsMio())
			CurrentTotalTrickPoints = Save::GetPersistentProfileCounter(n"TrickPointsMio");
		else
			CurrentTotalTrickPoints = Save::GetPersistentProfileCounter(n"TrickPointsZoe");
	}

	void RemoveTrickPoints(int PointsToRemove)
	{
		CurrentTotalTrickPoints -= PointsToRemove;
		
		if(CurrentTotalTrickPoints < 0)
			CurrentTotalTrickPoints = 0;
	}

	void IncreaseTrickMultiplier(float MultiplierIncrease)
	{
		if(!CurrentTrickCombo.IsSet())
			return;

		CurrentTrickCombo.Value.ComboMultiplier += MultiplierIncrease;
	}
};