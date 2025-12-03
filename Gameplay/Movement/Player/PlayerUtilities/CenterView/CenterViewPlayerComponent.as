enum ECenterViewTargetMode
{
	TapToCenter,
	HoldToCenter,
	SoftLock,
	HardLock,
	MAX
};

const FConsoleVariable CVar_CenterViewTargetMode("Haze.CenterViewTargetMode", DefaultValue = 3);

namespace CenterView
{
	ECenterViewTargetMode GetTargetMode()
	{
		return ECenterViewTargetMode(CVar_CenterViewTargetMode.Int);
	}

	bool AlwaysCenterBossActor()
	{
		ECenterViewTargetMode CenterViewMode = ECenterViewTargetMode(CVar_CenterViewTargetMode.Int);
		if(CenterViewMode == ECenterViewTargetMode::TapToCenter)
			return true;

		return false;
	};
}

struct FCenterViewForcedTarget
{
	FInstigator Instigator;
	EInstigatePriority Priority = EInstigatePriority::Normal;

	UCenterViewTargetComponent Target;
	FCenterViewApplyForcedTargetParams Params;

	bool IsValid() const
	{
		if(!Instigator.IsValid())
			return false;

		if(!::IsValid(Target))
			return false;

		return true;
	}

	int opCmp(const FCenterViewForcedTarget& Other) const
	{
		if(Priority > Other.Priority)
			return 1;
		else
			return -1;
	}
}

struct FCenterViewTarget
{
	UCenterViewTargetComponent Target;
	bool bIsForcedTarget = false;
	bool bAllowCenterViewInputToDeactivate = true;
	bool bAllowCameraInputToDeactivate = true;
	bool bClearOnDeactivated = false;
	bool bShowTutorial = true;

	FCenterViewTarget(FCenterViewForcedTarget InForcedTarget)
	{
		Target = InForcedTarget.Target;
		bIsForcedTarget = true;
		bAllowCenterViewInputToDeactivate = InForcedTarget.Params.bAllowCenterViewInputToDeactivate;
		bAllowCameraInputToDeactivate = InForcedTarget.Params.bAllowCameraInputToDeactivate;
		bClearOnDeactivated = InForcedTarget.Params.bClearOnDeactivate;
		bShowTutorial = InForcedTarget.Params.bShowTutorial;
	}
};

UCLASS(NotBlueprintable)
class UCenterViewPlayerComponent : UActorComponent
{
#if !RELEASE
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#else
	default PrimaryComponentTick.bStartWithTickEnabled = false;
#endif

	private AHazePlayerCharacter Player;
	private UCenterViewSettings Settings;
	private UCameraUserComponent CameraUserComp;
	private uint LastAppliedCenterViewFrame = 0;
	private FInstigator LastAppliedCenterViewInstigator;

	TArray<FCenterViewForcedTarget> ForcedCenterViewTargets;
	TOptional<FCenterViewTarget> CurrentCenterViewTarget;
	bool bIsCenteringTarget = false;
	float StartCenteringTargetRealTime = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		check(Player != nullptr);
		
		Settings = UCenterViewSettings::GetSettings(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

#if !RELEASE
		FHazeDevInputInfo CenterViewOnOff;
		CenterViewOnOff.Name = n"Center View Button";
		CenterViewOnOff.Category = n"Camera";
		CenterViewOnOff.AddAction(ActionNames::CenterView);
		CenterViewOnOff.OnTriggered.BindUFunction(this, n"OnCenterViewButton");
		CenterViewOnOff.OnStatus.BindUFunction(this, n"OnCenterViewStatus");
		Player.RegisterDevInput(CenterViewOnOff);

		FHazeDevInputInfo CenterViewMode;
		CenterViewMode.Name = n"Center View Mode";
		CenterViewMode.Category = n"Camera";
		CenterViewMode.AddAction(ActionNames::Interaction);
		CenterViewMode.OnTriggered.BindUFunction(this, n"OnCenterViewMode");
		CenterViewMode.OnStatus.BindUFunction(this, n"OnCenterViewModeStatus");
		Player.RegisterDevInput(CenterViewMode);

		UpdateCenterViewMode();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		const FTemporalLog TemporalLog = GetTemporalLog();
		if(Player.IsCapabilityTagBlocked(CapabilityTags::CenterView))
			TemporalLog.Status("CapabilityTag is Blocked", FLinearColor::Red);
		else if(HasViewTarget())
			TemporalLog.Status("Has View Target", FLinearColor::Green);
		else
			TemporalLog.Status("No View Target", FLinearColor::Yellow);

		if(CurrentCenterViewTarget.IsSet())
		{
			TemporalLog.Section("CenterViewTarget")
				.Value("Target", CurrentCenterViewTarget.Value.Target)
				// .Value("bIsForcedTarget", CurrentCenterViewTarget.Value.bIsForcedTarget)
				// .Value("TargetType", CurrentCenterViewTarget.Value.TargetType)
				// .Value("bShowTutorial", CurrentCenterViewTarget.Value.bShowTutorial)
			;
		}
		else
		{
			TemporalLog.Section("CenterViewTarget")
				.Value("Target", nullptr)
			;
		}

		TemporalLog
			.Value("HasAppliedCenterViewThisFrame", HasAppliedCenterViewThisFrame())
			.Value("LastAppliedCenterViewInstigator", LastAppliedCenterViewInstigator)
		;
#endif
	}

	UFUNCTION()
	private void OnCenterViewButton()
	{
		bool bLookForward = Player.IsUsingCenterView();

		if(Player.IsMio())
			Console::SetConsoleVariableBool("Haze.CameraCenterViewMio", !bLookForward);
		else
			Console::SetConsoleVariableBool("Haze.CameraCenterViewZoe", !bLookForward);
	}

	UFUNCTION()
	private void OnCenterViewStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		const FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
		if (Player.IsUsingCenterView())
		{
			OutDescription = f"{PlayerName}: On";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = f"{PlayerName}: Off";
			OutColor = FLinearColor::Red;
		}
	}

	UFUNCTION()
	private void OnCenterViewMode()
	{
		const int CenterViewModeIndex = (CVar_CenterViewTargetMode.Int + 1) % int(ECenterViewTargetMode::MAX);
		CVar_CenterViewTargetMode.SetInt(CenterViewModeIndex);
		UpdateCenterViewMode();
	}

	private void UpdateCenterViewMode()
	{
		const ECenterViewTargetMode CenterViewMode = ECenterViewTargetMode(CVar_CenterViewTargetMode.Int);

		for(auto PlayerIt : Game::Players)
		{
			UCenterViewSettings::ClearLockViewTarget(PlayerIt,this);
			UCenterViewSettings::ClearDisengageFromCameraInput(PlayerIt,this);

			switch(CenterViewMode)
			{
				case ECenterViewTargetMode::TapToCenter:
					UCenterViewSettings::SetLockViewTarget(PlayerIt, ECenterViewLockViewTarget::NoLock, this);
					break;
				case ECenterViewTargetMode::HoldToCenter:
					UCenterViewSettings::SetLockViewTarget(PlayerIt, ECenterViewLockViewTarget::Hold, this);
					break;
				case ECenterViewTargetMode::HardLock:
					UCenterViewSettings::SetLockViewTarget(PlayerIt, ECenterViewLockViewTarget::Toggle, this);
					UCenterViewSettings::SetDisengageFromCameraInput(PlayerIt, false, this);
					break;
				case ECenterViewTargetMode::SoftLock:
					UCenterViewSettings::SetLockViewTarget(PlayerIt, ECenterViewLockViewTarget::Toggle, this);
					UCenterViewSettings::SetDisengageFromCameraInput(PlayerIt, true, this);
					break;
			}
		}
	}

	UFUNCTION()
	private void OnCenterViewModeStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		ECenterViewTargetMode CenterViewMode = ECenterViewTargetMode(CVar_CenterViewTargetMode.Int);

		switch(CenterViewMode)
		{
			case ECenterViewTargetMode::TapToCenter:
			{
				OutDescription = "Tap To Center";
				OutColor = FLinearColor::LucBlue;
				break;
			}
			case ECenterViewTargetMode::HoldToCenter:
			{
				OutDescription = "Hold To Center";
				OutColor = FLinearColor::Yellow;
				break;
			}
			case ECenterViewTargetMode::HardLock:
			{
				OutDescription = "Hard Lock";
				OutColor = FLinearColor::Red;
				break;
			}
			case ECenterViewTargetMode::SoftLock:
			{
				OutDescription = "Soft Lock";
				OutColor = FLinearColor::Green;
				break;
			}
		}
	}

	bool CanApplyCenterView() const
	{
		if(!Player.IsUsingCenterView())
			return false;

		if (!CameraUserComp.CanControlCamera())
			return false;

		if(!CameraUserComp.IsUsingDefaultCamera())
			return false;

		return true;
	}

	bool HasAppliedCenterViewThisFrame() const
	{
		return LastAppliedCenterViewFrame == Time::FrameNumber;
	}

	void ApplyCenterView(FInstigator Instigator)
	{
		check(!HasAppliedCenterViewThisFrame());
		LastAppliedCenterViewFrame = Time::FrameNumber;
		LastAppliedCenterViewInstigator = Instigator;
	}

	bool HasViewTarget() const
	{
		return CurrentCenterViewTarget.IsSet() && CurrentCenterViewTarget.Value.Target != nullptr;
	}

	/**
	 * Has the rotation been active for long enough that it should have reached the target rotation by now?
	 * @param bRequireRotationActive Do we only count it if the rotation capability is active?
	 */
	bool ShouldHaveReachedTarget(bool bRequireRotationActive) const
	{
		if(bRequireRotationActive && !bIsCenteringTarget)
			return false;

		if(Time::GetRealTimeSince(StartCenteringTargetRealTime) < Settings.TurnDuration)
			return false;

		return true;
	}

	void OnCenterViewDeactivated()
	{
		if(CurrentCenterViewTarget.Value.bIsForcedTarget)
		{
			if(CurrentCenterViewTarget.Value.bClearOnDeactivated)
			{
				for(int i = ForcedCenterViewTargets.Num() - 1; i >= 0; i--)
				{
					if(ForcedCenterViewTargets[i].Target == CurrentCenterViewTarget.Value.Target)
					{
						ForcedCenterViewTargets.RemoveAt(i);
					}
				}
			}	
		}
		
		CurrentCenterViewTarget.Reset();
	}

	void ApplyForcedTarget(FCenterViewForcedTarget ForcedTarget)
	{
		for(auto& It : ForcedCenterViewTargets)
		{
			if(It.Instigator != ForcedTarget.Instigator)
				continue;

			It = ForcedTarget;
			return;
		}

		ForcedCenterViewTargets.Add(ForcedTarget);
		ForcedCenterViewTargets.Sort();
	}

	void ClearForcedTarget(FInstigator Instigator)
	{
		for(int i = ForcedCenterViewTargets.Num() - 1; i >= 0; i--)
		{
			if(ForcedCenterViewTargets[i].Instigator != Instigator)
				continue;

			ForcedCenterViewTargets.RemoveAt(i);
			return;
		}
	}

	bool TryGetForcedTarget(FCenterViewForcedTarget&out OutForcedTarget) const
	{
		if(ForcedCenterViewTargets.IsEmpty())
			return false;

		OutForcedTarget = ForcedCenterViewTargets[0];
		return true;
	}

#if !RELEASE
	protected FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(Owner, "Camera").Page("Center View");
	}
#endif

// #if EDITOR
// 	UFUNCTION(DevFunction)
// 	void BlockCenterViewRotation()
// 	{
// 		if(Player.IsCapabilityTagBlocked(CameraTags::CenterViewRotation))
// 			return;

// 		Player.BlockCapabilities(CameraTags::CenterViewRotation, this);
// 	}

// 	UFUNCTION(DevFunction)
// 	void UnblockCenterViewRotation()
// 	{
// 		if(!Player.IsCapabilityTagBlocked(CameraTags::CenterViewRotation))
// 			return;

// 		Player.UnblockCapabilities(CameraTags::CenterViewRotation, this);
// 	}
// #endif
};