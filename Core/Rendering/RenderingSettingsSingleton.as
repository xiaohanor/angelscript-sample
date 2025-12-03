enum ERenderingSettingMode
{
	On,
	Off,
	NeedMediumShaderQuality,
	NeedHighShaderQuality,
	NeedUltraShaderQuality,
	NeedMediumDetailMode,
	NeedHighDetailMode,
}

const FConsoleVariable CVar_DynamicResThrottlingSpec("Haze.DynamicResThrottlingSpec", 0);

class URenderingSettingsSingleton : UHazeSingleton
{
	TInstigated<ERenderingSettingMode> EnableSubsurfaceScattering(ERenderingSettingMode::On);
	TInstigated<ERenderingSettingMode> EnableScreenSpaceReflections(ERenderingSettingMode::On);

	TInstigated<float> ThrottledDynamicResNormalSpec(0.0);
	TInstigated<float> ThrottledDynamicResHighSpec(0.0);
	TInstigated<float> ViewDistanceScale(1.0);
	TInstigated<float> TextureBoost(1.0);

	bool bCutsceneSettingsActive = false;

	private bool bAppliedSSSEnabled = true;
	private bool bAppliedSSREnabled = true;
	private float AppliedDynamicResThrottle = 0.0;
	private float AppliedViewDistanceScale = 1.0;
	private float AppliedTextureBoost = 1.0;

	/**
	 * OBS! Don't use this to override console variables that are also set by either Device Profile
	 * ini file or by options menu settings! We don't want cutscenes to be able to turn on features that
	 * are turned off by the options menu completely!
	 */

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void ResetStateBetweenLevels()
	{
		EnableScreenSpaceReflections.Empty();
		EnableSubsurfaceScattering.Empty();
		ThrottledDynamicResHighSpec.Empty();
		ThrottledDynamicResNormalSpec.Empty();
		ViewDistanceScale.Empty();
		TextureBoost.Empty();
		UpdateInstigatedSettings();
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
		// We want SSS turned on in editor, for preview purposes, so we flip it back on when the subsystem
		// deinitializes, which signifies the end of PIE
		if (!bAppliedSSSEnabled)
			Console::SetConsoleVariableInt("r.SubsurfaceScattering", 1);
		if (!bAppliedSSREnabled)
			Console::SetConsoleVariableInt("ShowFlag.ScreenSpaceReflections", 2);
	}

	void ApplyCutsceneSettings()
	{
	}

	void ClearCutsceneSettings()
	{
	}

	bool ResolveSetting(ERenderingSettingMode Mode)
	{
		switch (Mode)
		{
			case ERenderingSettingMode::On:
				return true;
			case ERenderingSettingMode::Off:
				return false;
			case ERenderingSettingMode::NeedMediumShaderQuality:
				return Game::IsShaderQualityAtLeastMedium();
			case ERenderingSettingMode::NeedHighShaderQuality:
				return Game::IsShaderQualityAtLeastHigh();
			case ERenderingSettingMode::NeedUltraShaderQuality:
				return Game::IsShaderQualityAtLeastUltra();
			case ERenderingSettingMode::NeedMediumDetailMode:
				return Game::IsDetailModeAtLeastMedium();
			case ERenderingSettingMode::NeedHighDetailMode:
				return Game::IsDetailModeAtLeastHigh();
		}
	}

	void UpdateInstigatedSettings()
	{
		// Subsurface Scattering
		if (bAppliedSSSEnabled)
		{
			if (!ResolveSetting(EnableSubsurfaceScattering.Get()))
			{
				bAppliedSSSEnabled = false;
				Console::SetConsoleVariableInt("r.SubsurfaceScattering", 0);
			}
		}
		else
		{
			if (ResolveSetting(EnableSubsurfaceScattering.Get()))
			{
				bAppliedSSSEnabled = true;
				Console::SetConsoleVariableInt("r.SubsurfaceScattering", 1);
			}
		}

		// Screen Space Reflections
		if (bAppliedSSREnabled)
		{
			if (!ResolveSetting(EnableScreenSpaceReflections.Get()))
			{
				bAppliedSSREnabled = false;
				Console::SetConsoleVariableInt("ShowFlag.ScreenSpaceReflections", 0);
			}
		}
		else
		{
			if (ResolveSetting(EnableScreenSpaceReflections.Get()))
			{
				bAppliedSSREnabled = true;
				Console::SetConsoleVariableInt("ShowFlag.ScreenSpaceReflections", 2);
			}
		}

		// Dynamic resolution throttle
		float WantedDynamicResThrottle = 0.0;
		if (CVar_DynamicResThrottlingSpec.GetInt() == 1)
			WantedDynamicResThrottle = ThrottledDynamicResNormalSpec.Get();
		else if (CVar_DynamicResThrottlingSpec.GetInt() == 2)
			WantedDynamicResThrottle = ThrottledDynamicResHighSpec.Get();

		if (WantedDynamicResThrottle != AppliedDynamicResThrottle)
		{
			Console::SetConsoleVariableFloat("r.DynamicRes.ThrottlingMaxScreenPercentage", WantedDynamicResThrottle);
			AppliedDynamicResThrottle = WantedDynamicResThrottle;
		}

		// View distance scale
		if (ViewDistanceScale.Get() != AppliedViewDistanceScale)
		{
			if (ViewDistanceScale.Get() != 1.0)
			{
				Console::SetConsoleVariableFloat("r.ViewDistanceScale.SecondaryScale", ViewDistanceScale.Get(), bOverrideValueSetByConsole = true);
				Console::SetConsoleVariableInt("r.ViewDistanceScale.ApplySecondaryScale", 1, bOverrideValueSetByConsole = true);
			}
			else
			{
				Console::SetConsoleVariableFloat("r.ViewDistanceScale.SecondaryScale", 1.0, bOverrideValueSetByConsole = true);
				Console::SetConsoleVariableInt("r.ViewDistanceScale.ApplySecondaryScale", 0, bOverrideValueSetByConsole = true);
			}

			AppliedViewDistanceScale = ViewDistanceScale.Get();
		}

		// Texture boost
		if (TextureBoost.Get() != AppliedTextureBoost)
		{
			Console::SetConsoleVariableFloat("r.Streaming.Boost", TextureBoost.Get(), bOverrideValueSetByConsole = true);
			AppliedTextureBoost = TextureBoost.Get();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bWantCutsceneSettings = false;
		if (Game::Mio != nullptr)
		{
			// We are in a cutscene when we're fullscreen and one or more players are participating
			bWantCutsceneSettings = SceneView::IsPendingFullscreen()
				&& (Game::Mio.bIsParticipatingInCutscene || Game::Zoe.bIsParticipatingInCutscene);
		}
		else
		{
			// We don't have players, which means we could be on a loading screen or the main menu,
			// we just use cutscene settings in this case
			bWantCutsceneSettings = true;
		}

		if (bCutsceneSettingsActive != bWantCutsceneSettings)
		{
			bCutsceneSettingsActive = bWantCutsceneSettings;
			if (bCutsceneSettingsActive)
				ApplyCutsceneSettings();
			else
				ClearCutsceneSettings();
		}

		UpdateInstigatedSettings();
	}
}