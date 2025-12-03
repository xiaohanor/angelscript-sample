class USummitKnightHideShieldCapability : UHazeCapability
{	
	default CapabilityTags.Add(SummitKnightTags::SummitKnightShield);

	AAISummitKnight Knight;
	USummitMeltComponent MeltComp;
	UBasicAIKnockdownComponent KnockdownComp;
	USummitKnightShieldComponent Shield;
	USummitKnightDeprecatedSettings KnightSettings;
	bool bBlock;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Knight = Cast<AAISummitKnight>(Owner);
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		KnockdownComp = UBasicAIKnockdownComponent::GetOrCreate(Owner);
		Shield = USummitKnightShieldComponent::Get(Owner);
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!KnockdownComp.HasKnockdown())
			return false;
		if(bBlock)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(KnockdownComp.HasKnockdown())
			return false;
		if(MeltComp.bMelted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Shield.AddComponentVisualsBlocker(Owner);
		Shield.bEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(KnightSettings.AcidShieldRegenerate)
		{
			Shield.bEnabled = true;
			Shield.bReformed = false;
		}
		else
		{
			bBlock = true;
			Owner.BlockCapabilities(SummitKnightTags::SummitKnightShield, this);
		}
	}
}