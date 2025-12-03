class UPrisonBossMagneticCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Magnetic");

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonBoss Boss;

	TArray<int> MaterialSlotsToMagnetize;
	TArray<UMaterialInterface> OriginalMaterials;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);

		MaterialSlotsToMagnetize.Add(1);
		MaterialSlotsToMagnetize.Add(2);
		MaterialSlotsToMagnetize.Add(3);
		MaterialSlotsToMagnetize.Add(4);
		MaterialSlotsToMagnetize.Add(8);
		MaterialSlotsToMagnetize.Add(9);
		MaterialSlotsToMagnetize.Add(10);
		MaterialSlotsToMagnetize.Add(11);
		MaterialSlotsToMagnetize.Add(12);

		for (int MatSlot : MaterialSlotsToMagnetize)
		{
			OriginalMaterials.Add(Boss.Mesh.GetMaterial(MatSlot));
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.MagneticFieldResponseComp.bMagnetized)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.MagneticFieldResponseComp.bMagnetized)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (int MatSlot : MaterialSlotsToMagnetize)
		{
			Boss.Mesh.SetMaterial(MatSlot, Boss.MagneticMaterial);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		int MaterialIndex = 0;
		for (int MatSlot : MaterialSlotsToMagnetize)
		{
			Boss.Mesh.SetMaterial(MatSlot, OriginalMaterials[MaterialIndex]);
			MaterialIndex++;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}