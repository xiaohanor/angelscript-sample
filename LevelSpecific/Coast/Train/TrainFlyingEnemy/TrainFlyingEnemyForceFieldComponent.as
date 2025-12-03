class UTrainFlyingEnemyForceFieldComponent : UStaticMeshComponent
{
	float CurrentIntegrity = 1.0;
	FHazeAcceleratedFloat AccIntegrity;
	FVector LocalBreachLocation = FVector::ZeroVector;
	float LastDamageTime = -BIG_NUMBER;
	FVector BaseScale;

	UMaterialInstanceDynamic MaterialInstance;

	bool IsDepleted() const
	{
		// Never let through any damage to health, damage will instead allow players to grapple to us.
		return false;
	}

	bool IsBreached() const
	{
		return (CurrentIntegrity < SMALL_NUMBER);
	}

	bool IsDamaged() const
	{
		return (CurrentIntegrity < 1.0 - SMALL_NUMBER);
	}

	void TakeDamage(float Damage, FVector LocalImpactLocation)
	{
		if (AccIntegrity.Value > 0.99)
			LocalBreachLocation = LocalImpactLocation;

		CurrentIntegrity = Math::Max(0.0, CurrentIntegrity - Damage);
	}
	
	void Regenerate(float Regeneration)
	{
		CurrentIntegrity = Math::Min(1.0, CurrentIntegrity + Regeneration);
	}


	void InitializeVisuals()
	{
		BaseScale = WorldScale;

		if (GetMaterials().Num() == 0)
			return;

		MaterialInstance = Material::CreateDynamicMaterialInstance(this, GetMaterial(0));
		for (int i = 0; i < GetMaterials().Num(); i++)
		{
			SetMaterial(i, MaterialInstance);
		}

		if (MaterialInstance != nullptr)
		{
			SetVectorParameterValueOnMaterials(n"Color", FVector(0.1, 0.3, 0.1));
			SetVectorParameterValueOnMaterials(n"EdgeColor", FVector(1.6, 2.9, 0.5));
		}
	} 

	void UpdateVisuals(float DeltaTime)
	{
		// Update breach
		AccIntegrity.AccelerateTo(CurrentIntegrity, 0.5, DeltaTime);
		if (AccIntegrity.Value < 1.0 - SMALL_NUMBER)
		{
			float RadiusScaleFactor = 0.7;
			float Radius = (1.0 - AccIntegrity.Value);
			Radius *= BoundsRadius * RadiusScaleFactor;
			SetScalarParameterValueOnMaterials(n"Radius", Radius);

			FVector Front = WorldLocation - WorldRotation.ForwardVector * BoundsRadius;
			FVector BreachLocation = Front.SlerpTowards(WorldTransform.TransformPosition(LocalBreachLocation), AccIntegrity.Value);
			SetVectorParameterValueOnMaterials(n"DissolvePoint", BreachLocation);
		}

		// Wobble scale
		FVector Scale = BaseScale;
		Scale.X *= 1.0 + 0.05 * Math::Sin(Time::GameTimeSeconds * 7.23);
		Scale.Y *= 1.0 + 0.05 * Math::Sin(Time::GameTimeSeconds * 8.23);
		Scale.Z *= 1.0 + 0.05 * Math::Sin(Time::GameTimeSeconds * 7.67);
		WorldScale3D = Scale;

	}
}
