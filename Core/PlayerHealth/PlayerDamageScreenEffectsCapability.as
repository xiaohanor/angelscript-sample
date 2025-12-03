class UPlayerDamageScreenEffectsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerDamageScreenEffectComponent DamageScreenEffectComp;
	UPlayerHealthComponent HealthComp;
	UPostProcessingComponent PostProcessComp;
	UMaterialInstanceDynamic ScreenEffectDynamicMat;

	const float INTENSITY_BLEND_IN_SPEED = 10.0;
	const float INTENSITY_BLEND_OUT_SPEED = 2.0;

	const float RADIUS_BLEND_IN_SPEED = 10.0;
	const float RADIUS_BLEND_OUT_SPEED = 2.0;
	const float RADIUS_DEAD_BLEND_SPEED = 1.0;

	const float HIT_DURATION = 1.0;

	const float FLASH_DURATION = 0.1;
	const float FLASH_BLEND_IN_SPEED = 50.0;
	const float FLASH_BLEND_OUT_SPEED = 5.0;

	float HitIntensity = 0.0;
	float HitRadius = 0.0;
	float HitFlash = 0.0;
	float Desaturation = 0.0;

	UPlayerDamageScreenEffectWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DamageScreenEffectComp = UPlayerDamageScreenEffectComponent::GetOrCreate(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
		PostProcessComp = UPostProcessingComponent::Get(Player);
		ScreenEffectDynamicMat = Material::CreateDynamicMaterialInstance(this, HealthComp.DamageScreenEffectMaterial);
	}

	float GetHealthToDisplay() const
	{
		if (!DamageScreenEffectComp.OverrideDisplayedHealth.IsDefaultValue())
			return Math::Saturate(DamageScreenEffectComp.OverrideDisplayedHealth.Get());
		else
			return HealthComp.Health.GetDisplayHealth();
	}

	float GetLastDamageGameTime() const
	{
		if (!DamageScreenEffectComp.OverrideLastDamageGameTime.IsDefaultValue())
			return DamageScreenEffectComp.OverrideLastDamageGameTime.Get();
		else
			return HealthComp.Health.GameTimeAtMostRecentDamage;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GetHealthToDisplay() >= 1.0)
			return false;

		if (!CanShowDamageEffect())
			return false;

		if (!ShouldShowDamageEffect())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CanShowDamageEffect())
			return true;

		if (ShouldShowDamageEffect())
		{
			if (GetHealthToDisplay() < 1.0)
				return false;
		}

		if (HitIntensity > 0.0)
			return false;
		if (HitRadius > 0.0)
			return false;
		if (HitFlash > 0.0)
			return false;
		if (Desaturation > 0.0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Widget = Player.AddWidget(HealthComp.DamageScreenEffectWidget, EHazeWidgetLayer::Gameplay);
		Widget.SetWidgetZOrderInLayer(-1000);
		Widget.Image.SetBrushFromMaterial(ScreenEffectDynamicMat);

		HitIntensity = 0.0;
		HitRadius = 0.0;
		HitFlash = 0.0;
		Desaturation = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveWidget(Widget);
		Widget = nullptr;
	}

	/**
	 * When false, we don't allow showing the damage screen effect at all
	 */
	bool CanShowDamageEffect() const
	{
		if (SceneView::IsFullScreen())
		{
			if (!DamageScreenEffectComp.bAllowInFullScreen.Get())
				return false;

			if (Player != SceneView::FullScreenPlayer)
				return false;
		}

		return true;
	}

	/**
	 * When false, we don't deactivate, but we do fade out
	 */
	bool ShouldShowDamageEffect() const
	{
		if (Game::GetSingleton(UCameraSingleton).IsBlendingToFullScreen())
			return false;

		if (Player.IsCapabilityTagBlocked(n"DamageScreenEffects"))
			return false;

		if (SceneView::IsPendingFullscreen())
		{
			if(!DamageScreenEffectComp.bAllowInFullScreen.Get())
				return false;
			
			if(Player != SceneView::FullScreenPlayer)
				return false;

			return true;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Whenever we get hit, ramp up the damage intensity
		float TimeSinceHit = Time::GetGameTimeSince(GetLastDamageGameTime());
		float TargetIntensity = 1.0;

		if (ShouldShowDamageEffect())
		{
			if (GetHealthToDisplay() >= 1.0)
				TargetIntensity = 0.0;

			// if (TimeSinceHit < HIT_DURATION)
			// 	TargetIntensity = 1.0;

			float HitBlendSpeed = HitIntensity < TargetIntensity ? INTENSITY_BLEND_IN_SPEED : INTENSITY_BLEND_OUT_SPEED;
			HitIntensity = Math::FInterpConstantTo(HitIntensity, TargetIntensity, DeltaTime, HitBlendSpeed);

			// When we get hit, flash for a short duration as well
			float TargetFlash = 0.0;
			if (TimeSinceHit < FLASH_DURATION + (1.0 / FLASH_BLEND_IN_SPEED))
				TargetFlash = 1.0;

			float FlashBlendSpeed = HitFlash < TargetFlash ? FLASH_BLEND_IN_SPEED : FLASH_BLEND_OUT_SPEED;
			HitFlash = Math::FInterpTo(HitFlash, TargetFlash, DeltaTime, FlashBlendSpeed);

			// The radius of the damage effect increases depending on how much health we've already lost
			float TargetRadius = Math::GetMappedRangeValueClamped(
				FVector2D(1.0, 0.0),
				FVector2D(0.0, 1.0),
				GetHealthToDisplay(),
			);

			// if (TimeSinceHit < HIT_DURATION)
			// 	TargetRadius += 0.1;

			float RadiusBlendSpeed = HitRadius < TargetRadius ? RADIUS_BLEND_IN_SPEED : RADIUS_BLEND_OUT_SPEED;
			if (Player.IsPlayerDead() && Time::GetGameTimeSince(HealthComp.GameTimeOfDeath) > 1.0)
			{
				TargetRadius = 0.0;
				RadiusBlendSpeed = RADIUS_DEAD_BLEND_SPEED;
			}

			HitRadius = Math::FInterpConstantTo(HitRadius, TargetRadius, DeltaTime, RadiusBlendSpeed);

			// Desaturate slightly as our health gets lower
			Desaturation = Math::GetMappedRangeValueClamped(
				FVector2D(0.55, 0.45),
				FVector2D(0.0, 0.35),
				GetHealthToDisplay()
			);
		}
		else
		{
			HitIntensity = Math::FInterpConstantTo(HitIntensity, 0.0, DeltaTime, 2.0);
			HitFlash = Math::FInterpConstantTo(HitFlash, 0.0, DeltaTime, 2.0);
			HitRadius = Math::FInterpConstantTo(HitRadius, 0.0, DeltaTime, 2.0);
			Desaturation = Math::FInterpConstantTo(Desaturation, 0.0, DeltaTime, 2.0);
		}

		ScreenEffectDynamicMat.SetScalarParameterValue(n"Desaturation", Desaturation);
		ScreenEffectDynamicMat.SetScalarParameterValue(n"Damage", HitIntensity);
		ScreenEffectDynamicMat.SetScalarParameterValue(n"DamageRadius", HitRadius);
		ScreenEffectDynamicMat.SetScalarParameterValue(n"DamageFlash", HitFlash);
	}
};

class UPlayerDamageScreenEffectWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage Image;
}