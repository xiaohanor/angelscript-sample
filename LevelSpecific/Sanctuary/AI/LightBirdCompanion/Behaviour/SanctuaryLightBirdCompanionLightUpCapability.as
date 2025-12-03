class USanctuaryLightBirdCompanionLightUpCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);

	default TickGroup = EHazeTickGroup::Gameplay;

	FHazeAcceleratedFloat AcceleratedFloat;
	UPointLightComponent LightShadowCasting;
	UPointLightComponent LightAmbient;
	bool bInside = false;
	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

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
		AcceleratedFloat.SnapTo(0.0, 0.0);
		LightShadowCasting = UPointLightComponent::Create(Owner);
		LightShadowCasting.SetAttenuationRadius(100000.0);
		LightShadowCasting.SetLightColor(FLinearColor(1.00, 0.97, 0.72));
		LightShadowCasting.SetUseInverseSquaredFalloff(false);
		LightShadowCasting.SetLightFalloffExponent(8.0);
		LightShadowCasting.SetIntensity(0.0);
		LightShadowCasting.SetVisibility(false);

		LightAmbient = UPointLightComponent::Create(Owner);
		LightAmbient.SetAttenuationRadius(100000.0);
		LightAmbient.SetLightColor(FLinearColor(1.00, 0.97, 0.72));
		LightAmbient.SetUseInverseSquaredFalloff(false);
		LightAmbient.SetLightFalloffExponent(4.0);
		LightAmbient.SetIntensity(0.0);
		LightAmbient.SetCastShadows(false);
		LightAmbient.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightShadowCasting.DestroyComponent(LightShadowCasting);
		LightAmbient.DestroyComponent(LightAmbient);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcceleratedFloat.AccelerateTo((bInside ? 1.0 : 0.0), 2.0, DeltaTime);
		LightShadowCasting.SetIntensity(AcceleratedFloat.Value * 2.0);
		LightShadowCasting.SetAttenuationRadius(AcceleratedFloat.Value * 10000.0);
		LightAmbient.SetIntensity(AcceleratedFloat.Value * 0.1);
		LightAmbient.SetAttenuationRadius(AcceleratedFloat.Value * 10000.0);

		bInside = false;

		if (Math::IsNearlyZero(AcceleratedFloat.Value))
		{
			if (bIsActive)
			{
				bIsActive = false;
				LightShadowCasting.SetVisibility(false);
				LightAmbient.SetVisibility(false);
			}
		}
		else
		{
			if (!bIsActive)
			{
				bIsActive = true;
				LightShadowCasting.SetVisibility(true);
				LightAmbient.SetVisibility(true);
			}			
		}

		TListedActors<ASanctuaryLightBirdLightUpVolume> LightUpVolumes;
		for (auto LightUpVolume : LightUpVolumes)
		{
			if (Shape::IsPointInside(LightUpVolume.Shape.CollisionShape, LightUpVolume.ActorTransform, Owner.ActorLocation))
			{
				bInside = true;
			}
		}
	}
};