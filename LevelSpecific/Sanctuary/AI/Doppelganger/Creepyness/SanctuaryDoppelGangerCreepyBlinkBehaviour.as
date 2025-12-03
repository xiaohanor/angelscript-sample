class USanctuaryDoppelGangerCreepyBlinkBehaviour : UBasicBehaviour
{
	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;
	UHazeSkeletalMeshComponentBase Mesh;

	float BlinkTime = BIG_NUMBER;
	float EndTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return false;
		if(Time::GameTimeSeconds < DoppelComp.StartCreepyTime + DoppelSettings.CreepyBlinkDelay)
			return false;
		if (IsNearPlayerView())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return true;
		if (Time::GameTimeSeconds > EndTime)
		 	return true;
		return false;
	}

	bool IsNearPlayerView() const
	{
		FVector HeadLoc = Owner.FocusLocation;
		AHazePlayerCharacter PlayerToCreepOut = DoppelComp.MimicTarget.OtherPlayer;
		if (!PlayerToCreepOut.ViewLocation.IsWithinDist(HeadLoc, DoppelSettings.CreepyBlinkViewMinRange))
			return false;
		if (PlayerToCreepOut.ViewRotation.Vector().DotProduct(HeadLoc - PlayerToCreepOut.ViewLocation) < 0.0)
			return false; // Behind view
		return true;
	}

	int GetEyesMaterialIndex(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			return 3;
		return 3;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Mesh.SetMaterial(GetEyesMaterialIndex(DoppelComp.MimicTarget), DoppelComp.CreepyEyesMaterial);
		EndTime = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Mesh.SetMaterial(GetEyesMaterialIndex(DoppelComp.MimicTarget), DoppelComp.MimicTarget.Mesh.GetMaterial(GetEyesMaterialIndex(DoppelComp.MimicTarget)));
		Cooldown.Set(DoppelSettings.CreepyBlinkCooldown);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Test for material index
		// for (int i = 0; i < DoppelComp.MimicTarget.Mesh.NumMaterials; i++)
		// 	Mesh.SetMaterial(i, DoppelComp.MimicTarget.Mesh.GetMaterial(i));
		// Mesh.SetMaterial(GetEyesMaterialIndex(DoppelComp.MimicTarget), DoppelComp.CreepyEyesMaterial);

		if ((EndTime == BIG_NUMBER) && IsNearPlayerView())
			EndTime = Time::GameTimeSeconds + DoppelSettings.CreepyBlinkDiscoverDuration;
	}
}


