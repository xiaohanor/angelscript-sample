class UTundraShapeshiftingChangeSettingTriggerBoxSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Zoe")
	FTundraPlayerFairySettingsOverride FairySettingsOverride;

	UPROPERTY(Category = "Zoe")
	FTundraPlayerZoeSettingsOverride ZoeSettingsOverride;

	UPROPERTY(Category = "Zoe")
	FTundraPlayerTreeGuardianSettingsOverride TreeGuardianSettingsOverride;

	UPROPERTY(Category = "Mio")
	FTundraPlayerOtterSettingsOverride OtterSettingsOverride;

	UPROPERTY(Category = "Mio")
	FTundraPlayerMioSettingsOverride MioSettingsOverride;

	UPROPERTY(Category = "Mio")
	FTundraChangeSettingsSnowMonkeyOverride SnowMonkeySettingsOverride;
}

struct FTundraPlayerFairySettingsOverride
{
	UPROPERTY()
	UTundraPlayerFairySettings FairySettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	void Apply(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ApplySettings(FairySettings, Instigator);

		if(CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(CameraSettings, 2, Instigator, EHazeCameraPriority::High);
		}
	}

	void Reset(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ClearSettingsByInstigator(Instigator);
		Player.ClearCameraSettingsByInstigator(Instigator);
	}
}

struct FTundraPlayerZoeSettingsOverride
{
	UPROPERTY()
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;
	
	void Apply(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ApplySettings(FloorMotionSettings, Instigator);

		if(CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(CameraSettings, 2, Instigator, EHazeCameraPriority::High);
		}
	}

	void Reset(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ClearSettingsByInstigator(Instigator);
		Player.ClearCameraSettingsByInstigator(Instigator);
	}
}

struct FTundraPlayerTreeGuardianSettingsOverride
{
	UPROPERTY()
	UTundraPlayerTreeGuardianSettings TreeGuardianSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	void Apply(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ApplySettings(TreeGuardianSettings, Instigator);

		if(CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(CameraSettings, 2, Instigator, EHazeCameraPriority::High);
		}
	}

	void Reset(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ClearSettingsByInstigator(Instigator);
		Player.ClearCameraSettingsByInstigator(Instigator);
	}
}

struct FTundraPlayerOtterSettingsOverride
{
	UPROPERTY()
	UTundraPlayerOtterSettings OtterSettings;

	UPROPERTY()
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY()
	UPlayerJumpSettings JumpSettings;

	UPROPERTY()
	UTundraPlayerOtterSwimmingSettings SwimmingSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	void Apply(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ApplySettings(OtterSettings, Instigator);
		Player.ApplySettings(FloorMotionSettings, Instigator);
		Player.ApplySettings(JumpSettings, Instigator);
		Player.ApplySettings(SwimmingSettings, Instigator);

		if(CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(CameraSettings, 2, Instigator, EHazeCameraPriority::High);
		}
	}

	void Reset(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ClearSettingsByInstigator(Instigator);
		Player.ClearCameraSettingsByInstigator(Instigator);
	}
}

struct FTundraPlayerMioSettingsOverride
{
	UPROPERTY()
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	void Apply(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ApplySettings(FloorMotionSettings, Instigator);

		if(CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(CameraSettings, 2, Instigator, EHazeCameraPriority::High);
		}
	}

	void Reset(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ClearSettingsByInstigator(Instigator);
		Player.ClearCameraSettingsByInstigator(Instigator);
	}
}

struct FTundraChangeSettingsSnowMonkeyOverride
{
	UPROPERTY()
	UTundraPlayerSnowMonkeySettings SnowMonkeySettings;

	UPROPERTY()
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	void Apply(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ApplySettings(SnowMonkeySettings, Instigator);
		Player.ApplySettings(FloorMotionSettings, Instigator);

		if(CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(CameraSettings, 2, Instigator, EHazeCameraPriority::High);
		}
	}

	void Reset(AHazePlayerCharacter Player, UObject Instigator)
	{
		Player.ClearSettingsByInstigator(Instigator);
		Player.ClearCameraSettingsByInstigator(Instigator);
	}
}