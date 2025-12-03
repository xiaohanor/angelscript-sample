class UVisualizeDecalRecieve
{
	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const {
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);

		if (StaticMeshComponent != nullptr) {

			for (UMaterialInterface MaterialInterface: StaticMeshComponent.GetMaterials()) {
				if (MaterialInterface.GetBlendMode() != EBlendMode::BLEND_Opaque) {
					return false;
				}
			}
			
			bool bOverlapsWithDecal = false;

			#if EDITOR
			FScopeDebugEditorWorld EditorWorld;
			FBox A = StaticMeshComponent.GetBounds().Box;
			TArray<ADecalActor> Decals = Editor::GetAllEditorWorldActorsOfClass(ADecalActor);
			for (ADecalActor Decal : Decals) {
				FVector Origin;
				FVector Extents;
				Decal.GetActorBounds(bOnlyCollidingComponents = false, Origin = Origin, BoxExtent = Extents, bIncludeFromChildActors = false);
				FBox B = FBox(Origin - Extents, Origin + Extents);

				if (A.Intersect(B)) {
					bOverlapsWithDecal = true;
					break;
				}
			}
			#endif

			if (bOverlapsWithDecal) {
				OutColor = FLinearColor(0.8, 0.0, 0.8);
			} else {
				OutColor = StaticMeshComponent.bReceivesDecals ? FLinearColor(0.0, 1.0, 0.0) : FLinearColor(1.0, 0.0, 0.0);
			}

			return true;
		}

		return false;
	}
}