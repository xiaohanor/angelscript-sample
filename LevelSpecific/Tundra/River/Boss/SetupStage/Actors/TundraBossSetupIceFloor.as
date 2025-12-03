class ATundraSetupIceFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh03;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh04;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh05;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh06;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh07;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh08;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SupportMesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SupportMesh02;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FXLoc;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakIceBigFX;

	UPROPERTY(EditAnywhere)
	ATundraBossSetup Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// for(auto BreakIceActors : TundraBossSetupBreakIceFloorActor::GetAllBreakIceFloorActors())
		// {
		// 	Boss.OnIceKingBrokeFloor.AddUFunction(this, n"OnIceKingBrokeFloor");
		// }

		// let the fluid seem know about the pieces
		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);
		for (auto MeshIter : MeshComps)
		{
			MeshIter.AddTag(n"FluidSim");
		}

	}

	UFUNCTION()
	void OnIceKingBrokeFloor(int BreakIceIteration)
	{
		if (!devEnsure(BreakIceIteration < 2, "Trying to Break IceFloor, but there are no pieces that should break"))
			return;

		switch(BreakIceIteration)
		{
			case 0:
			BreakIceFloorPiece(Mesh01);
			BreakIceFloorPiece(Mesh05);
			BreakIceFloorPiece(Mesh06);
			BreakIceFloorPiece(SupportMesh02);
			break;

			case 1:
			BreakIceFloorPiece(Mesh08);
			BreakIceFloorPiece(SupportMesh01);
			break;
		}
	}

	void BreakIceFloorPiece(UStaticMeshComponent Mesh)
	{
		Mesh.SetHiddenInGame(true);
		Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
		Mesh.RemoveTag(n"FluidSim");
	}

	//Breaks the entire floor
	void BreakIceFloor()
	{
		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);

		for(auto Mesh : MeshComps)
		{
			Mesh.SetHiddenInGame(true);
			Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakIceBigFX, FXLoc.WorldLocation);
	}

#if EDITOR
	void PreviewIceIteration(int BreakIceIteration)
	{
		switch(BreakIceIteration)
		{
			case 0:
			BreakIceFloorPiece(Mesh01);
			BreakIceFloorPiece(Mesh05);
			BreakIceFloorPiece(Mesh06);
			break;

			case 1:
			BreakIceFloorPiece(Mesh08);
			break;
		}
	}

	void UnHideIceFloorPieces()
	{
		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);

		for (auto Mesh : MeshComps)
		{
			Mesh.SetHiddenInGame(false);
			Mesh.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		}
	}
#endif
};

namespace TundraBossSetupIceFloor
{
	UFUNCTION()
	ATundraSetupIceFloor GetIceFloor()
	{
		return TListedActors<ATundraSetupIceFloor>().GetSingle();
	}
};