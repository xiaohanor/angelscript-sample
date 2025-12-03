namespace GamepadTags
{
	const FName GamepadLight = n"GamepadLight";
}

class UPlayerGamepadLightCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastDemotable;
	default CapabilityTags.Add(GamepadTags::GamepadLight);

	UPlayerDamageScreenEffectComponent DamageScreenEffectComponent;
	UPlayerHealthComponent HealthComponent;

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		return false;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DamageScreenEffectComponent = UPlayerDamageScreenEffectComponent::GetOrCreate(Player);
		HealthComponent = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearGamepadLightColor(this);
	}

	// Account for player swapping
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(HealthComponent.bIsRespawning)
		{
			FLinearColor LinearColor = FLinearColor::White;
			Player.ApplyGamepadLightColor(LinearColor.ToFColor(true), this, EInstigatePriority::Normal);
		}
		else if(!HealthComponent.bIsDead)
		{
			// Assign player color, handling health stuff
			float Alpha = Math::Square(GetHealthToDisplay());
			// Oscilate faster the closer we get to 0 health
			float Offset = Math::Sin(Time::GameTimeSeconds * 12 * (2 - Alpha)) * 0.1 * GetHealthToDisplay();

			FLinearColor LinearColor = Math::Lerp(FLinearColor::Black, GamePadPlayerColor(), Alpha + Offset);

			Player.ApplyGamepadLightColor(LinearColor.ToFColor(true), this, EInstigatePriority::Normal);
		}
		else
		{
			if(HealthComponent.bRespawnTimerActive)
			{
				float Alpha = (HealthComponent.RespawnTimer) * 0.1;
				FLinearColor LinearColor = Math::Lerp(FLinearColor::Black, GamePadPlayerColor(), Alpha);

				LinearColor = LinearColor * HealthComponent.RespawnTimer*0.1;

				Player.ApplyGamepadLightColor(LinearColor.ToFColor(true), this, EInstigatePriority::Normal);
			}
			else
				Player.ApplyGamepadLightColor(FLinearColor::Black.ToFColor(true), this, EInstigatePriority::Normal);
		}
    }
	
	FLinearColor GamePadPlayerColor()
	{
			FLinearColor PlayerColor;
			if(Player.IsMio())
				PlayerColor = GetColorForPlayer(Player.Player);
			if(Player.IsZoe())
				PlayerColor = FLinearColor::MakeFromHex(0xff92f400);
		return PlayerColor;
	}

	// Lifted from PlayerDamageScreenEffectsCapability
	float GetHealthToDisplay() const
	{
		if (!DamageScreenEffectComponent.OverrideDisplayedHealth.IsDefaultValue())
			return Math::Saturate(DamageScreenEffectComponent.OverrideDisplayedHealth.Get());
		else
			return HealthComponent.Health.GetDisplayHealth();
	}
}