class UCameraDebugUserComponent : UActorComponent
{
	bool bUsingDebugCamera = false;
	ADebugCameraActor DebugCamera;

	bool bUsingDebugAnimationInspection = false;
	FName FocusDebugType = NAME_None;
}
