event void FPerformAnAction();

class AMeltdownRader : AHazeActor
{
	UPROPERTY()
	FPerformAnAction ActionPerformed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{				
	}

	UFUNCTION(BlueprintCallable)
	void Bp_PerformAction()
	{
		ActionPerformed.Broadcast();				
	}

};

class UMeltdownBonanzaRaderRenderComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Manager = ASplitBonanzaManager::Get();
		Manager.SplitRenderComp.AddActorToSplit(
			Owner,
			Manager.SplitLines[4].Name
		);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!GetWorld().IsGameWorld())
			return;

		auto Manager = ASplitBonanzaManager::Get();
		if (Manager == nullptr)
			return;

		auto Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		auto OverlayMat = Cast<UMaterialInstanceDynamic>(Mesh.OverlayMaterial);
		if (OverlayMat != nullptr)
			OverlayMat.SetScalarParameterValue(n"MeltdownHeightCutoff", Manager.SplitLines[4].ActorLocation.Z);

		for (int i = 0, Count = Mesh.GetNumMaterials(); i < Count; ++i)
		{
			auto Mat = Cast<UMaterialInstanceDynamic>(Mesh.GetMaterial(i));

			FLinearColor Params = Mat.GetVectorParameterValue(n"Meltdown_MeltdownParameters");
			Params.G = Manager.SplitLines[4].ActorLocation.Z;
			Mat.SetVectorParameterValue(n"MeltdownHeightCutoff", Params);
		}
	}
}