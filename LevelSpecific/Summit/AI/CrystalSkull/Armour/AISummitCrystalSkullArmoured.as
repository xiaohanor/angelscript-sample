UCLASS(Abstract)
class AAISummitCrystalSkullArmoured : AAISummitCrystalSkullBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalSkullArmourCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalSkullRegrowArmourCapability");

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = MeshOffsetComponent)
	USummitCrystalSkullArmourComponent ArmourComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = MeshOffsetComponent)
	USummitCrystalSkullShieldComponent Shield;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = ArmourComp)
	UStaticMeshComponent ArmourPreviewComp;
	default ArmourPreviewComp.bHiddenInGame = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ArmourPreviewComp.SetVisibility(false);

		if (!ArmourComp.ArmourClass.IsValid())		
			return;
		ASummitCrystalSkullArmour ArmourCDO = Cast<ASummitCrystalSkullArmour>(ArmourComp.ArmourClass.Get().DefaultObject);
		if (ArmourCDO == nullptr)
			return;
		ArmourPreviewComp.SetVisibility(true);
		ArmourPreviewComp.StaticMesh = ArmourCDO.MainMesh.StaticMesh;
		ArmourPreviewComp.RelativeTransform = ArmourCDO.MainMesh.RelativeTransform;
		for (int i = 0; i < ArmourCDO.MainMesh.NumMaterials; i++)
		{
			ArmourPreviewComp.SetMaterial(i, ArmourCDO.MainMesh.GetMaterial(i));
		}
	}

	UFUNCTION(DevFunction)
	void DebugDestroy()
	{
		ArmourComp.Armour.Destroy();
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Game::Zoe);
	}
#endif
}
