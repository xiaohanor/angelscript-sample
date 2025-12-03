class USkylineEnforcerBodyFieldComponent: UPoseableMeshComponent
{
	private TInstigated<bool> bEnabled;

	UPROPERTY(EditAnywhere)
	UMaterialInstance BodyFieldMaterial;
	
	UMaterialInstanceDynamic MaterialInstance;
	
	float ResistTime;
	float ResistDuration = 0.5;

	FLinearColor DefaultColor;
	FHazeAcceleratedVector AccResistColor;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto OwnerCharacter = Cast<AHazeCharacter>(Owner);
		if (OwnerCharacter == nullptr || OwnerCharacter.Mesh == nullptr)
			return;
		InitializeVisuals(OwnerCharacter.Mesh);
	}

	void InitializeVisuals(UHazeSkeletalMeshComponentBase BaseMeshComp)
	{
		SetSkinnedAssetAndUpdate(BaseMeshComp.SkeletalMeshAsset); // TODO: enforce lower LOD
		SetWorldScale3D(BaseMeshComp.GetWorldScale());

		MaterialInstance = Material::CreateDynamicMaterialInstance(this, BodyFieldMaterial);
		for (int i = 0; i < BaseMeshComp.SkeletalMeshAsset.GetMaterials().Num(); i++)
		{
			SetMaterial(i, MaterialInstance);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeSkeletalMeshComponentBase CharacterMeshComp = Cast<AHazeCharacter>(Owner).Mesh;
		InitializeVisuals(CharacterMeshComp);
		SetLeaderPoseComponent(CharacterMeshComp);
		DefaultColor = MaterialInstance.GetVectorParameterValue(n"Color");

		UGravityBladeCombatResponseComponent BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");	
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!IsEnabled())
			return;
			ResistedDamage();
	}

	void ResistedDamage()
	{
		AccResistColor.SnapTo(FVector(50, 50, 50));
		ResistTime = Time::GameTimeSeconds;
	}

	bool IsEnabled()
	{
		return bEnabled.Get();
	}

	void Enable(FInstigator Instigator)
	{
		bEnabled.Apply(true, Instigator);
		RemoveComponentVisualsBlocker(Instigator);
	}

	void Disable(FInstigator Instigator)
	{
		bEnabled.Apply(false, Instigator);
		AddComponentVisualsBlocker(Instigator);
	}
}
