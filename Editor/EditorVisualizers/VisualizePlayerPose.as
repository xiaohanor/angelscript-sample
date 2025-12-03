/*
  Create an editor-only visualizer mesh for a player,
  to indicate particular points in the editor scene.
*/
UFUNCTION()
UPlayerEditorVisualizerComponent CreatePlayerEditorVisualizer(
        USceneComponent AttachTo,
        EHazePlayer Player,
        FTransform RelativePosition,
		USkeletalMesh CustomMeshClass = nullptr
)
{
    auto Mesh = UPlayerEditorVisualizerComponent::Create(AttachTo.Owner);
    Mesh.AttachTo(AttachTo);
    Mesh.RelativeTransform = RelativePosition;
	Mesh.bIsEditorOnly = true;
	Mesh.IsVisualizationComponent = true;
	Mesh.CastShadow = false;
	Mesh.SetHiddenInGame(true);
	Mesh.SetAvoidSubsurfaceInView(0, true);
	Mesh.SetAvoidSubsurfaceInView(1, true);

	Mesh.SetComponentTickEnabled(false);

	if(CustomMeshClass != nullptr)
	{
		Mesh.SetSkeletalMeshAsset(CustomMeshClass);
	}
	else
	{
		auto Variant = AHazeLevelScriptActor::GetEditorPlayerVariant();
		if (Player == EHazePlayer::Mio)
			Mesh.SetSkeletalMeshAsset(Variant.MioSkeletalMesh);
		else
			Mesh.SetSkeletalMeshAsset(Variant.ZoeSkeletalMesh);
	}

	return Mesh;
}