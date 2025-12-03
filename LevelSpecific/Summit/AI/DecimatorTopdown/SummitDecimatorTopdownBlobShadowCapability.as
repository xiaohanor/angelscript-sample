class USummitDecimatorTopdownBlobShadowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BlobShadow");
	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownBlobShadowComponent BlobShadowComp;
	UDecalComponent ShadowDecal;
	UBasicAIHealthComponent HealthComp;
	UMaterialInstanceDynamic DynamicMaterial;
	UHazeMovementComponent MoveComp;
	AAISummitDecimatorTopdown Decimator;
	float GroundZ;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{	
		ShadowDecal = UDecalComponent::Create(Owner, n"BlobShadow");
		BlobShadowComp = USummitDecimatorTopdownBlobShadowComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"Reset");
		ShadowDecal.SetAbsolute(true, true, true);
		ShadowDecal.SetDecalMaterial(BlobShadowComp.ShadowDecalMaterial);
		ShadowDecal.SetHiddenInGame(true);
		DynamicMaterial = ShadowDecal.CreateDynamicMaterialInstance();

		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void Reset(AHazeActor ActorBeingKilled)
	{
		ShadowDecal.SetHiddenInGame(true);
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
		if(!MoveComp.ShapeComponent.IsCollisionEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.IsHidden())
			return true;
		if(!MoveComp.ShapeComponent.IsCollisionEnabled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Decimator = Cast<AAISummitDecimatorSpikeBomb>(Owner).DecimatorOwner;
		GroundZ = Decimator.ArenaCenterLocation.Z;
		ShadowDecal.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ShadowDecal.SetHiddenInGame(true);
		DynamicMaterial.SetScalarParameterValue(n"Decal_Opacity", 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();

		auto GroundHit = Trace.QueryTraceSingle(
			Owner.ActorLocation + Owner.MovementWorldUp * 50.0,
			Owner.ActorLocation + Owner.MovementWorldUp * -5000.0,
		);

		if (GroundHit.bBlockingHit)
		{
			// Hack for preventing shadow decal on the edge of the arena.
			if (!MoveComp.IsOnAnyGround() && GroundHit.ImpactPoint.Z - GroundZ > 100)
				return;

			float Distance = Math::Abs(GroundHit.ImpactPoint.Z - Owner.ActorLocation.Z);
			float Opacity = BlobShadowComp.OpacityCurve.GetFloatValue(Distance);
			float Size = BlobShadowComp.SizeCurve.GetFloatValue(Distance) * BlobShadowComp.SizeFactor;

			if (Opacity >= 0.01)
			{
				ShadowDecal.SetHiddenInGame(false);
				ShadowDecal.SetWorldTransform(
					FTransform(
						FQuat::MakeFromX(Owner.MovementWorldUp),
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