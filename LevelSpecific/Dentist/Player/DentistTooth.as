/**
 * Purely visual help when setting up the player tooth.
 */
UCLASS(Abstract)
class ADentistTooth : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDentistGooglyEyeSpawnerComponent LeftEyeSpawner;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDentistGooglyEyeSpawnerComponent RightEyeSpawner;

#if EDITOR
	UPROPERTY(DefaultComponent)
	private UHazeCharacterSkeletalMeshComponent EditorPreviewMeshComp;
	default EditorPreviewMeshComp.bHiddenInGame = true;
	default EditorPreviewMeshComp.bIsEditorOnly = true;
#endif

	void OnAttached(AHazePlayerCharacter Player)
	{
		LeftEyeSpawner.AttachToComponent(Player.Mesh, n"LeftEyeAttach", EAttachmentRule::SnapToTarget);
		RightEyeSpawner.AttachToComponent(Player.Mesh, n"RightEyeAttach", EAttachmentRule::SnapToTarget);
	}
};