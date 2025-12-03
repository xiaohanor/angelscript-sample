class USplitBonanzaBlobShadowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BlobShadow");
	default TickGroup = EHazeTickGroup::Gameplay;

	UPROPERTY()
	UMaterialInterface ShadowDecalMaterial;
	UPROPERTY()
	UCurveFloat OpacityCurve;
	UPROPERTY()
	UCurveFloat SizeCurve;

	UDecalComponent ShadowDecal;
	UMaterialInstanceDynamic DynamicMaterial;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShadowDecal = UDecalComponent::Create(Owner, n"BonanzaBlobShadow");
		ShadowDecal.SetAbsolute(true, true, true);
		ShadowDecal.SetDecalMaterial(ShadowDecalMaterial);
		ShadowDecal.SetHiddenInGame(true);
		DynamicMaterial = ShadowDecal.CreateDynamicMaterialInstance();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ShadowDecal.DestroyComponent(ShadowDecal);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.IsHidden())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.IsHidden())
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
		Trace.TraceWithProfile(n"BlockAll");
		Trace.IgnoreActor(Owner);
		Trace.IgnorePlayers();
		Trace.UseLine();

		auto GroundHit = Trace.QueryTraceSingle(
			Owner.ActorLocation + FVector::UpVector * 50.0,
			Owner.ActorLocation + FVector::UpVector * -2000.0,
		);

		if (GroundHit.bBlockingHit)
		{
			float Distance = Math::Abs(GroundHit.ImpactPoint.Z - Owner.ActorLocation.Z);
			float Opacity = OpacityCurve.GetFloatValue(Distance);
			float Size = SizeCurve.GetFloatValue(Distance) * 0.15;

			if (Opacity >= 0.01)
			{
				ShadowDecal.SetHiddenInGame(false);
				ShadowDecal.SetWorldTransform(
					FTransform(
						FQuat::MakeFromX(FVector::UpVector),
						GroundHit.ImpactPoint,
						FVector(Size, Size, Size),
					)
				);

				DynamicMaterial.SetScalarParameterValue(n"Decal_Opacity", Opacity);
			}
			else
			{
				ShadowDecal.SetHiddenInGame(true);
			}
		}
		else
		{
			ShadowDecal.SetHiddenInGame(true);
		}
	}
};