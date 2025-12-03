class UIslandOverseerVisorCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AAIIslandOverseer Overseer;
	UIslandOverseerVisorComponent Visor;
	UBasicAIAnimationComponent AnimComp;
	FHazeAcceleratedRotator AccRotation;

	FLinearColor Color6;
	FLinearColor Color7;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		Visor = UIslandOverseerVisorComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		AccRotation.SnapTo(Visor.RelativeRotation);
		Color6 = Overseer.Mesh.CreateDynamicMaterialInstance(6).GetVectorParameterValue(n"EmissiveColor");
		Color7 = Overseer.Mesh.CreateDynamicMaterialInstance(7).GetVectorParameterValue(n"EmissiveColor");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Visor.bOpen && Visor.bOpening)
			return true;
		if(Visor.bOpen && Visor.bClosing)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Visor.bOpening && ActiveDuration > Visor.OpenDuration)
			return true;
		else if(Visor.bClosing && ActiveDuration > Visor.CloseDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Visor.bOpening)
		{
			Visor.bOpen = true;
			Visor.bOpening = false;
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", FLinearColor::Black);
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", FLinearColor::Black);
		}
		else
		{
			Visor.bOpen = false;
			Visor.bClosing = false;
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", Color6);
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", Color7);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ClosingStart = Visor.CloseDuration - 0.5;
		if(Visor.bClosing && ActiveDuration > Visor.CloseDuration - 0.5)
		{
			float Alpha = Math::Clamp((ActiveDuration - ClosingStart) * 2, 0, 1);
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", Math::Lerp(FLinearColor::Black, Color6, Alpha));
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", Math::Lerp(FLinearColor::Black, Color7, Alpha));
		}

		if(Visor.bOpening)
		{
			float Alpha = Math::Clamp(ActiveDuration * 2, 0, 1);
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", Math::Lerp(Color6, FLinearColor::Black, Alpha));
			Overseer.Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", Math::Lerp(Color7, FLinearColor::Black, Alpha));
		}
	}
}