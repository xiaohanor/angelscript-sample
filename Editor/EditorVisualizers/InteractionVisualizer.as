void CreateInteractionEditorVisualizer(
        USceneComponent AttachTo,
        EHazeSelectPlayer Player = EHazeSelectPlayer::Both,
        FTransform RelativePosition = FTransform::Identity
)
{
    auto Mesh = UStaticMeshComponent::Create(AttachTo.Owner);
    Mesh.AttachTo(AttachTo);
    Mesh.RelativeTransform = RelativePosition;
	Mesh.bIsEditorOnly = true;
	Mesh.IsVisualizationComponent = true;

	Mesh.SetComponentTickEnabled(false);
	Mesh.SetHiddenInGame(true);
	Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh.SetStaticMesh(Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Editor/Interaction/EditorGizmos_Interactpoint.EditorGizmos_Interactpoint")));

	if (Player == EHazeSelectPlayer::Mio)
		Mesh.SetMaterial(0, Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/Editor/Interaction/Dev_Gizmo_Interaction_Mio.Dev_Gizmo_Interaction_Mio")));
	else if (Player == EHazeSelectPlayer::Zoe)
		Mesh.SetMaterial(0, Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/Editor/Interaction/Dev_Gizmo_Interaction_Zoe.Dev_Gizmo_Interaction_Zoe")));
}