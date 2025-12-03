
class USkylineEnforcerBodyFieldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::AfterPhysics;

	USkylineEnforcerBodyFieldComponent ForceFieldComp;
	UBasicAIHealthComponent HealthComp;

	default CapabilityTags.Add(n"SkylineEnforcerBodyField");
	
	float RedImpactTime;
	float BlueImpactTime;

	float RespawnCooldownTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceFieldComp = USkylineEnforcerBodyFieldComponent::Get(Owner);
		ForceFieldComp.Enable(this);	
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		ForceFieldComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		ForceFieldComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ForceFieldComp.ResistTime == 0)
			return;
		if(Time::GetGameTimeSince(ForceFieldComp.ResistTime) > ForceFieldComp.ResistDuration)
			return;

		ForceFieldComp.AccResistColor.AccelerateTo(FVector(ForceFieldComp.DefaultColor.R, ForceFieldComp.DefaultColor.G, ForceFieldComp.DefaultColor.B), ForceFieldComp.ResistDuration, DeltaTime);
		FLinearColor Color = FLinearColor(ForceFieldComp.AccResistColor.Value.X, ForceFieldComp.AccResistColor.Value.Y, ForceFieldComp.AccResistColor.Value.Z, 0);
		ForceFieldComp.MaterialInstance.SetVectorParameterValue(n"Color", Color);
	}
}