class USummitDecimatorTopdownSpearDecalCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpearDecal");
	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownBlobShadowComponent BlobShadowComp;
	UDecalComponent ShadowDecal;
	UHazeActorRespawnableComponent RespawnComp;
	UMaterialInstanceDynamic DynamicMaterial;

	FVector Ground;

	bool bShouldActivate = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{	
		ShadowDecal = UDecalComponent::Get(Owner);
		BlobShadowComp = USummitDecimatorTopdownBlobShadowComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		ShadowDecal.SetAbsolute(true, true, true);
		ShadowDecal.SetDecalMaterial(BlobShadowComp.ShadowDecalMaterial);
		ShadowDecal.SetHiddenInGame(true);
		DynamicMaterial = ShadowDecal.CreateDynamicMaterialInstance();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bShouldActivate = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ShadowDecal.DestroyComponent(ShadowDecal);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!bShouldActivate)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ShadowDecal.IsHiddenInGame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShadowDecal.SetHiddenInGame(false);
		bShouldActivate = false;
		
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		FHitResult Hit = Trace.QueryTraceSingle(Owner.ActorLocation + FVector::UpVector * 1500, Owner.ActorLocation - FVector::UpVector * 1000);
		if (Hit.bBlockingHit)
			Ground = Hit.ImpactPoint;			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ShadowDecal.SetHiddenInGame(true);
		Ground = FVector::ZeroVector;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Opacity = 0.5 + Math::Clamp(ActiveDuration, 0, 0.5);
		float Size = 0.2 + Math::Clamp(Math::Sin( (ActiveDuration-0.8) * 4.0) * 0.1, 0, 1);
	
		ShadowDecal.SetWorldTransform(FTransform(
					FQuat::MakeFromX(Owner.ActorUpVector),
					Ground,
					FVector(Size, Size, Size),
				));
		DynamicMaterial.SetScalarParameterValue(n"Decal_Opacity", Opacity);
	}
};