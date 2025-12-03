class USketchbookCopyStencilValueComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	EHazePlayer PlayerToCopyFrom;

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		const AHazePlayerCharacter Player = Game::GetPlayer(PlayerToCopyFrom);

		auto SkelMesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		if (SkelMesh != nullptr)
		{
			SkelMesh.SetRenderCustomDepth(true);
			SkelMesh.SetCustomDepthStencilValue(Player.Mesh.CustomDepthStencilValue);
		}
	}
};