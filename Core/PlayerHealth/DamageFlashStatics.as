namespace DamageFlash
{

UFUNCTION()
void DamageFlash(UPrimitiveComponent Mesh, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{
	// Widget components cannot damage flash
	if (Mesh.IsA(UWidgetComponent))
		return;

	// Loop through all materials on the mesh and trigger the flash.
	for (int i = 0; i < Mesh.GetNumMaterials(); i++)
	{
		if (Mesh.GetMaterial(i) == nullptr)
			continue;
		auto MatInst = Mesh.CreateDynamicMaterialInstance(i);
		if (MatInst == nullptr)
			continue;
		
		MatInst.SetScalarParameterValue(n"damageFlash_Time", Time::GetGameTimeSeconds());
		MatInst.SetScalarParameterValue(n"damageFlash_Duration", Duration);
		MatInst.SetVectorParameterValue(n"damageFlash_Color", Color);
	}
}

UFUNCTION()
void DamageFlashClear(UPrimitiveComponent Mesh)
{
	// Widget components cannot damage flash
	if (Mesh.IsA(UWidgetComponent))
		return;

	// Loop through all materials on the mesh and trigger the flash.
	for (int i = 0; i < Mesh.GetNumMaterials(); i++)
	{
		if (Mesh.GetMaterial(i) == nullptr)
			continue;
		auto MatInst = Mesh.CreateDynamicMaterialInstance(i);
		if (MatInst == nullptr)
			continue;
		
		MatInst.SetScalarParameterValue(n"damageFlash_Time", 0.f);
		MatInst.SetScalarParameterValue(n"damageFlash_Duration", 0.f);
		MatInst.SetVectorParameterValue(n"damageFlash_Color", FLinearColor::Transparent);
	}
}

UFUNCTION()
void DamageFlashMaterialIndex(UPrimitiveComponent Mesh, int MaterialIndex, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{ 
	auto MatInst = Mesh.CreateDynamicMaterialInstance(MaterialIndex);
	if (MatInst == nullptr)
		return;
	
	MatInst.SetScalarParameterValue(n"damageFlash_Time", Time::GetGameTimeSeconds());
	MatInst.SetScalarParameterValue(n"damageFlash_Duration", Duration);
	MatInst.SetVectorParameterValue(n"damageFlash_Color", Color);
}


// Will find components on the actor and cause them to flash
UFUNCTION()
void DamageFlashActor(AActor Actor, float Duration = 0.1f, FLinearColor Color = FLinearColor(1,1,1,1))
{
	TArray<UMeshComponent> MeshComponents; 
	Actor.GetComponentsByClass(MeshComponents);

	for (UMeshComponent MeshComponent : MeshComponents)
	{
		DamageFlash(MeshComponent, Duration, Color);
	}
}

UFUNCTION()
void DamageFlashPlayer(AHazePlayerCharacter Player, float Duration = 0.1, FLinearColor Color = FLinearColor(1,1,1,1))
{
	// Flash all components attached to the player
	TArray<USceneComponent> Comps;
	Comps.Reserve(32);
	Comps.Add(Player.RootComponent);

	int CheckIndex = 0;
	while (CheckIndex < Comps.Num())
	{
		USceneComponent Comp = Comps[CheckIndex];

		// Flash any meshes that are attached
		auto MeshComp = Cast<UMeshComponent>(Comp);
		if (MeshComp != nullptr)
			DamageFlash(MeshComp, Duration, Color);

		// Recurse through children of this component
		for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
		{
			auto Child = Comp.GetChildComponent(i);
			if (Child != nullptr)
				Comps.AddUnique(Child);
		}

		CheckIndex += 1;
	}
}

UFUNCTION()
void ClearPlayerFlash(AHazePlayerCharacter Player)
{
	// Flash all components attached to the player
	TArray<USceneComponent> Comps;
	Comps.Reserve(32);
	Comps.Add(Player.RootComponent);

	int CheckIndex = 0;
	while (CheckIndex < Comps.Num())
	{
		USceneComponent Comp = Comps[CheckIndex];

		// Flash any meshes that are attached
		auto MeshComp = Cast<UMeshComponent>(Comp);
		if (MeshComp != nullptr)
			DamageFlashClear(MeshComp);

		// Recurse through children of this component
		for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
		{
			auto Child = Comp.GetChildComponent(i);
			if (Child != nullptr)
				Comps.AddUnique(Child);
		}

		CheckIndex += 1;
	}
}

}