class USanctuaryDarkPortalCompanionMeshRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(n"MeshRotation");

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UHazeSkeletalMeshComponentBase Mesh;
	USanctuaryDarkPortalCompanionSettings Settings;
	FHazeAcceleratedFloat AccWorldPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::Get(Owner); 
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CompanionComp.TargetMeshPitch.GetCurrentInstigator() == FInstigator())
			return false;
		return false;
		// TODO: The jank is still strong with this one, need to fix walker stuff now
		//return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CompanionComp.TargetMeshPitch.GetCurrentInstigator() == FInstigator() &&
			Math::IsNearlyZero(AccWorldPitch.Value))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccWorldPitch.SnapTo(Mesh.WorldRotation.Pitch);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mesh.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (CompanionComp.TargetMeshPitch.GetCurrentInstigator() == FInstigator())
		{
			if (Owner.IsHidden())
				AccWorldPitch.SnapTo(0.0);
			else
				AccWorldPitch.AccelerateTo(0.0, Settings.MeshRotationClearDuration, DeltaTime);
		}
		else 
		{
			float TargetPitch = FRotator::NormalizeAxis(CompanionComp.TargetMeshPitch.Get());
			if (Owner.IsHidden())
				AccWorldPitch.SnapTo(TargetPitch);
			else 
				AccWorldPitch.AccelerateTo(TargetPitch, Settings.MeshRotationApplyDuration, DeltaTime);
			FRotator Rot = Mesh.WorldRotation;
			Rot.Pitch = AccWorldPitch.Value;
			Mesh.WorldRotation = Rot;
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FRotator MeshRot = Mesh.WorldRotation;
			MeshRot.Pitch = CompanionComp.TargetMeshPitch.Get();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Mesh.WorldRotation.ForwardVector * 200.0, FLinearColor::Purple, 3);
			if (CompanionComp.TargetMeshPitch.GetCurrentInstigator() != FInstigator())
				Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + MeshRot.ForwardVector * 150, FLinearColor::DPink, 5);
		}
#endif		
	}
};