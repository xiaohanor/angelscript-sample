class ASketchbookLadder : ALadder
{
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(UStaticMeshComponent, MeshComps);

		for (auto Mesh : MeshComps)
		{
			Mesh.bNeverDistanceCull = true;
			Mesh.SetRenderCustomDepth(true);
			Mesh.CustomDepthStencilValue = 50;
			Mesh.CullDistance = 5;

			Mesh.Mobility = EComponentMobility::Movable;
		}
	}
};