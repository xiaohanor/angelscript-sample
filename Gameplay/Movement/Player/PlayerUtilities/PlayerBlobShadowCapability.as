class UPlayerBlobShadowSettings : UHazeComposableSettings
{
	UPROPERTY()
	UCurveFloat OpacityCurve;

	UPROPERTY()
	UCurveFloat SizeCurve;
};

class UPlayerBlobShadowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::PlayerShadow);
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default TickGroup = EHazeTickGroup::Gameplay;

	UPROPERTY()
	UMaterialInterface ShadowDecalMaterial;

	UPROPERTY()
	UPlayerBlobShadowSettings DefaultSettings;

	UPlayerBlobShadowSettings Settings;
	UDecalComponent ShadowDecal;
	UMaterialInstanceDynamic DynamicMaterial;
	UPlayerMovementComponent MoveComp;

	float CurrentOpacity;
	float CurrentSize;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player.ApplyDefaultSettings(DefaultSettings);
		Settings = UPlayerBlobShadowSettings::GetSettings(Player);

		ShadowDecal = UDecalComponent::Create(Player, n"BlobShadow");
		ShadowDecal.SetAbsolute(true, true, true);
		ShadowDecal.SetDecalMaterial(ShadowDecalMaterial);
		ShadowDecal.SetHiddenInGame(true);
		DynamicMaterial = ShadowDecal.CreateDynamicMaterialInstance();

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ShadowDecal.DestroyComponent(ShadowDecal);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsHidden())
			return false;
		if (MoveComp.IsOnAnyGround())
			return false;
		if(!MoveComp.ShapeComponent.IsCollisionEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsHidden())
			return true;
		if (CurrentOpacity <= 0.0 && MoveComp.IsOnAnyGround())
			return true;
		if(!MoveComp.ShapeComponent.IsCollisionEnabled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShadowDecal.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ShadowDecal.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: This could probably use an async trace?

		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		Trace.UseLine();

		auto GroundHit = Trace.QueryTraceSingle(
			Player.MeshOffsetComponent.WorldLocation + Player.MovementWorldUp * 50.0,
			Player.MeshOffsetComponent.WorldLocation + Player.MovementWorldUp * -2000.0,
		);

		float TargetOpacity = CurrentOpacity;
		if (GroundHit.bBlockingHit)
		{
			float Distance = Math::Abs((GroundHit.ImpactPoint - Player.MeshOffsetComponent.WorldLocation).DotProduct(Player.MovementWorldUp));
			TargetOpacity = Settings.OpacityCurve.GetFloatValue(Distance);
			CurrentSize = Settings.SizeCurve.GetFloatValue(Distance) * 0.15;

		}
		else
		{
			TargetOpacity = 0;
			ShadowDecal.SetHiddenInGame(true);
		}

		CurrentOpacity = Math::FInterpConstantTo(
			CurrentOpacity, TargetOpacity,
			DeltaTime, 2.0
		);

		if (CurrentOpacity >= 0.01)
		{
			ShadowDecal.SetHiddenInGame(false);
			ShadowDecal.SetWorldTransform(
				FTransform(
					FQuat::MakeFromX(Player.MovementWorldUp),
					GroundHit.ImpactPoint,
					FVector(CurrentSize, CurrentSize, CurrentSize),
				)
			);

			DynamicMaterial.SetScalarParameterValue(n"Decal_Opacity", CurrentOpacity);
		}
		else
		{
			ShadowDecal.SetHiddenInGame(true);
		}
	}
};