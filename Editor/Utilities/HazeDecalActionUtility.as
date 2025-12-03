// Select menu Select All With Same Material but working for Decals
class UDecalActionUtility : UScriptActorMenuExtension {
	default SupportedClasses.Add(ADecalActor);

	UFUNCTION(CallInEditor, Category = "Select All With Same Material")
	void SelectAllWithSameMaterial() {
		TSet<UMaterialInterface> SelectedDecalMaterials;
		for (AActor Actor : Editor::GetSelectedActors()) {
			if (Actor.IsA(ADecalActor)) {
				ADecalActor Decal = Cast<ADecalActor>(Actor);
				UDecalComponent Comp = Decal.GetComponentByClass(UDecalComponent);
				UMaterialInterface Material = Comp.GetDecalMaterial();

				// Nullptr check for unset decal materials
				if (Material == nullptr) {
					continue;
				}

				SelectedDecalMaterials.Add(Material);
			}
		}

		TArray<AActor> DecalsToSelect;
		for (AActor Actor : Editor::GetAllEditorWorldActorsOfClass(ADecalActor)) {
			ADecalActor Decal = Cast<ADecalActor>(Actor);
			UDecalComponent Comp = Decal.GetComponentByClass(UDecalComponent);
			UMaterialInterface Material = Comp.GetDecalMaterial();

			if (SelectedDecalMaterials.Contains(Material)) {
				DecalsToSelect.Add(Actor);
			}
		}

		Editor::SelectActors(DecalsToSelect);
	}
}