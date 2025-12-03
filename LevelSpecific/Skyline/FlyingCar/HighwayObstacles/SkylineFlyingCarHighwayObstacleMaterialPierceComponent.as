class USkylineFlyingCarHighwayObstacleMaterialPierceComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	private const int MaxHits = 10;
	private int HitCount = 0;

	private UMaterialInstanceDynamic DynamicMaterial = nullptr;

	UFUNCTION()
	void Initialize(UMeshComponent MeshComponent)
	{
		// Create and assign dynamic material
		if (MeshComponent != nullptr)
			DynamicMaterial = MeshComponent.CreateDynamicMaterialInstance(0);
	}

	UFUNCTION()
	void TakeHit(FSkylineFlyingCarGunHit Damage)
	{
		if (DynamicMaterial == nullptr)
			return;

		int Index = HitCount % 10;
		FName LocationParameter = FName("Bubble" + Index + "Loc");
		DynamicMaterial.SetVectorParameterValue(LocationParameter, FLinearColor(Damage.WorldImpactLocation));

		FName RadiusParameter = FName("Bubble" + Index + "Radius");
		float Radius = Math::RandRange(100.0, 250.0);
		DynamicMaterial.SetScalarParameterValue(RadiusParameter, Radius);

		HitCount++;
	}
}