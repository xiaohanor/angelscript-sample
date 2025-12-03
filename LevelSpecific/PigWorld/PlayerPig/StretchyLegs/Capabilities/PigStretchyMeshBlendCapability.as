class UPigStretchyMeshBlendCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastDemotable;

	UPlayerPigStretchyLegsComponent StretchyLegsComponent;
	UGoldenApplePlayerComponent ApplePlayerComponent;

	const float BlendInDuration = 0.1;
	const float BlendOutDuration = 0.1;

	bool bBlendedOut = false;
	float LastSpringyMeshTimeStamp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Owner);
		ApplePlayerComponent = UGoldenApplePlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StretchyLegsComponent.IsSpringyMeshActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bBlendedOut)
			return true;

		return false;
	}

	// We are blending in springy mesh
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Move apple to spring mesh
		if (ApplePlayerComponent.IsCarryingApple())
			ApplePlayerComponent.CurrentApple.AttachToComponent(StretchyLegsComponent.SpringyMeshComponent, ApplePlayerComponent.AttachNodeName);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bBlendedOut = false;
		LastSpringyMeshTimeStamp = 0;

		// Move apple back to its rightful owner
		if (ApplePlayerComponent.IsCarryingApple())
			ApplePlayerComponent.CurrentApple.AttachToComponent(Player.Mesh, ApplePlayerComponent.AttachNodeName);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = 0;
		if (StretchyLegsComponent.IsSpringyMeshActive())
		{
			Alpha = Math::Saturate(ActiveDuration / BlendInDuration);
			LastSpringyMeshTimeStamp = ActiveDuration;
		}
		else
		{
			float DeactivationDuration = ActiveDuration - LastSpringyMeshTimeStamp;
			Alpha = 1.0 - Math::Saturate(DeactivationDuration / BlendOutDuration);

			if (Alpha <= 0.0)
				bBlendedOut = true;
		}

		Alpha = Math::Pow(Alpha, 4);

		StretchyLegsComponent.SpringyMeshComponent.SetScalarParameterValueOnMaterials(n"DitherFade", Alpha);
		Player.Mesh.SetScalarParameterValueOnMaterials(n"DitherFade", 1.0 - Alpha);
	}
}