const FConsoleVariable CVar_CameraAssistSettings("Haze.CameraAssistSettings", 1, "[0: Old] [1: New]");

enum ECameraAssistSettings
{
	Old,
	New,
	MAX
};

/**
 * A component placed on the player, containing all the information about the camera assist
 */
UCLASS(Abstract)
class UCameraAssistComponent : UActorComponent
{
#if !RELEASE
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#else
	default PrimaryComponentTick.bStartWithTickEnabled = false;
#endif

	UPROPERTY(Category = "Settings")
	protected UPlayerCameraAssistSettings DefaultAssistSettings;

	UPROPERTY(Category = "Settings")
	protected UCameraAssistType DefaultAssistType;

	protected TInstigated<UCameraAssistType> ActiveAssistType;
	protected TArray<FInstigator> ActiveAssisters;
	FCameraAssistSettingsData ActiveAssistSettings;
	
	TInstigated<float> ContextualMultiplier;
	default ContextualMultiplier.DefaultValue = 1;

	private AHazePlayerCharacter Player;

	UPROPERTY(Category = "New")
	protected UCameraAssistType NewAssistType;
	UPROPERTY(Category = "New", EditDefaultsOnly)
	protected UPlayerCameraAssistSettings NewSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		ActiveAssistType.DefaultValue = DefaultAssistType;

		if(DefaultAssistSettings != nullptr)
		{
			Player.ApplySettings(DefaultAssistSettings, this, EHazeSettingsPriority::Defaults);
		}

#if !RELEASE
		{
			FHazeDevInputInfo DevInput;
			DevInput.Name = n"Camera Assist";
			DevInput.Category = n"Camera";
			DevInput.AddAction(ActionNames::MovementJump);
			DevInput.OnTriggered.BindUFunction(this, n"OnCameraAssist");
			DevInput.OnStatus.BindUFunction(this, n"OnCameraAssistStatus");
			Player.RegisterDevInput(DevInput);
		}

		{
			FHazeDevInputInfo DevInput;
			DevInput.Name = n"Use New Assist";
			DevInput.Category = n"Camera";
			DevInput.AddAction(ActionNames::MovementDash);
			DevInput.OnTriggered.BindUFunction(this, n"OnCameraAssistTest");
			DevInput.OnStatus.BindUFunction(this, n"OnCameraAssistTestStatus");
			Player.RegisterDevInput(DevInput);
		}
#endif

		UpdateUseNewSettings();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		GetTemporalLog().Section("ActiveAssistSettings")
			.Value("AssistType", ActiveAssistSettings.AssistType)

			.Point("CurrentViewLocation", ActiveAssistSettings.CurrentViewLocation)
			.Rotation("CurrentViewRotation", ActiveAssistSettings.CurrentViewRotation, ActiveAssistSettings.CurrentViewLocation)

			.Value("CameraInput", ActiveAssistSettings.CameraInput)
			.Value("MovementInputRaw", ActiveAssistSettings.MovementInputRaw)
			.Value("InputSensitivity", ActiveAssistSettings.InputSensitivity)
			.Value("FollowSensitivity", ActiveAssistSettings.FollowSensitivity)

			.DirectionalArrow("UserVelocity", Player.ActorLocation, ActiveAssistSettings.UserVelocity)
			.DirectionalArrow("UserWorldUp", Player.ActorLocation, ActiveAssistSettings.UserWorldUp * 100)

			.Value("InputMultiplier", ActiveAssistSettings.InputMultiplier)
			.Value("ContextualMultiplier", ActiveAssistSettings.ContextualMultiplier)
			.Value("ActiveDuration", ActiveAssistSettings.ActiveDuration)

			.Value("bApplyYaw", ActiveAssistSettings.bApplyYaw)
			.Value("bApplyPitch", ActiveAssistSettings.bApplyPitch)

			.Value("Settings", ActiveAssistSettings.Settings)
			.Value("CameraUserSettings", ActiveAssistSettings.CameraUserSettings)

			.Value("LastCameraInputTime", ActiveAssistSettings.LastCameraInputTime)
			.Value("LastNoCameraInputTime", ActiveAssistSettings.LastNoCameraInputTime)
			.Value("LastCameraInputFrame", ActiveAssistSettings.LastCameraInputFrame)

			.Value("LastMovementInputTime", ActiveAssistSettings.LastMovementInputTime)
			.Value("LastNoMovementInputTime", ActiveAssistSettings.LastNoMovementInputTime)

			.Rotation("ControlRotation", ActiveAssistSettings.ControlRotation, Player.ActorLocation)

			.Value("LocalUserVelocity", ActiveAssistSettings.LocalUserVelocity)
			.Value("LocalUserRotation", ActiveAssistSettings.LocalUserRotation)
			.Value("LocalUserWorldUp", ActiveAssistSettings.LocalUserWorldUp)

			.Value("LocalViewRotation", ActiveAssistSettings.LocalViewRotation)
			.Value("LocalVerticalAxis", ActiveAssistSettings.LocalVerticalAxis)

			.Value("bIsGrounded", ActiveAssistSettings.bIsGrounded)
			.DirectionalArrow("VerticalAxis", Player.ActorLocation, ActiveAssistSettings.VerticalAxis * 100)
		;
#endif
	}

	UFUNCTION()
	private void OnCameraAssist()
	{
		FString ConsoleVar;
		
		if(Player.IsMio())
			ConsoleVar = "Haze.CameraChaseAssistanceMio";
		else
			ConsoleVar = "Haze.CameraChaseAssistanceZoe";

		bool bCameraAssist = Console::GetConsoleVariableBool(ConsoleVar);
		Console::SetConsoleVariableBool(ConsoleVar, !bCameraAssist, bOverrideValueSetByConsole = true);
	}

	UFUNCTION()
	private void OnCameraAssistStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		const FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
		if (Player.IsUsingCameraAssist())
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
	private void OnCameraAssistTest()
	{
		const int CameraAssistSettingsIndex = (CVar_CameraAssistSettings.Int + 1) % int(ECameraAssistSettings::MAX);
		CVar_CameraAssistSettings.SetInt(CameraAssistSettingsIndex);
		UpdateUseNewSettings();
	}

	UFUNCTION()
	private void OnCameraAssistTestStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		ECameraAssistSettings CameraAssistSettings = ECameraAssistSettings(CVar_CameraAssistSettings.Int);
		switch(CameraAssistSettings)
		{
			case ECameraAssistSettings::Old:
			{
				OutDescription = "Old";
				OutColor = FLinearColor::Red;
				break;
			}

			case ECameraAssistSettings::New:
			{
				OutDescription = "New";
				OutColor = FLinearColor::Green;
				break;
			}
		}
	}

	private void UpdateUseNewSettings()
	{
		const ECameraAssistSettings CameraAssistSettings = ECameraAssistSettings(CVar_CameraAssistSettings.Int);
		const FInstigator Instigator(this, n"Test");

		for(auto PlayerIt : Game::Players)
		{
			auto AssistCompIt = UCameraAssistComponent::Get(PlayerIt);
			if(AssistCompIt == nullptr)
				continue;

			AssistCompIt.ClearAssistType(Instigator);
			PlayerIt.ClearSettingsByInstigator(Instigator);

			switch(CameraAssistSettings)
			{
				case ECameraAssistSettings::Old:
					break;

				case ECameraAssistSettings::New:
					AssistCompIt.ApplyAssistType(NewAssistType, Instigator, EInstigatePriority::Low);
					PlayerIt.ApplySettings(NewSettings, Instigator, EHazeSettingsPriority::Sheet);
					break;
			}
		}
	}

	void AddAssistEnabled(FInstigator Instigator)
	{
		ActiveAssisters.AddUnique(Instigator);
	}

	void RemoveAssistEnabled(FInstigator Instigator)
	{
		ActiveAssisters.RemoveSingleSwap(Instigator);
	}

	bool IsAssistEnabled() const
	{
		return ActiveAssisters.Num() > 0;
	}

	void ApplyAssistType(UCameraAssistType Type, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		ActiveAssistType.Apply(Type, Instigator, Priority);
	}

	void ClearAssistType(FInstigator Instigator)
	{
		ActiveAssistType.Clear(Instigator);
	}

	UCameraAssistType GetAssistType() const
	{
		return ActiveAssistType.Get();
	}

	FInstigator GetAssistInstigator() const
	{
		return ActiveAssistType.CurrentInstigator;
	}

	EInstigatePriority GetAssistPriority() const
	{
		return ActiveAssistType.CurrentPriority;
	}

#if !RELEASE
	protected FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(Owner, "Camera").Page("Assist");
	}
#endif
};