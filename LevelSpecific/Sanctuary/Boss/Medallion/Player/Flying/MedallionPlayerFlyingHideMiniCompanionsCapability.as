class UMedallionPlayerFlyingHideMiniCompanionsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);

	UMedallionPlayerComponent MedallionComp;

	UPROPERTY()
	FDarkPortalInvestigationDestination DarkPortalInvestigationDestination;
	default DarkPortalInvestigationDestination.OverrideSpeed = 8000;

	UPROPERTY()
	FLightBirdInvestigationDestination LightBirdInvestigationDestination;
	default LightBirdInvestigationDestination.OverrideSpeed = 8000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MedallionComp.IsMedallionCoopFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
		{
			AAISanctuaryLightBirdCompanion Companion = LightBirdCompanion::GetLightBirdCompanion();
			Companion.SetActorScale3D(FVector::OneVector);
			Companion.AddActorVisualsBlock(this);
			LightBirdInvestigationDestination.TargetComp = Player.Mesh;
			LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination, this);
		}
		else
		{
			AAISanctuaryDarkPortalCompanion Companion = DarkPortalCompanion::GetDarkPortalCompanion();
			Companion.SetActorScale3D(FVector::OneVector);
			Companion.AddActorVisualsBlock(this);		
			DarkPortalInvestigationDestination.TargetComp = Player.Mesh;
			DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Player.IsMio())
		{
			AAISanctuaryLightBirdCompanion Companion = LightBirdCompanion::GetLightBirdCompanion();
			if (Companion != nullptr)
				Companion.RemoveActorVisualsBlock(this);

			ULightBirdUserComponent User = ULightBirdUserComponent::Get(Player);
			if (User != nullptr && User.Companion != nullptr)
				LightBirdCompanion::LightBirdStopInvestigating(this);
		}
		else
		{
			AAISanctuaryDarkPortalCompanion Companion = DarkPortalCompanion::GetDarkPortalCompanion();
			if (Companion != nullptr)
				Companion.RemoveActorVisualsBlock(this);
			UDarkPortalUserComponent User = UDarkPortalUserComponent::Get(Player);
			if (User != nullptr && User.Companion != nullptr)
				DarkPortalCompanion::DarkPortalStopInvestigating(this);
		}
	}
};
