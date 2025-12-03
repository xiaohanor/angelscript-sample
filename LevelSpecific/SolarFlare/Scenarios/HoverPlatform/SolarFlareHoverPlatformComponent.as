enum ESolarFlareHoverPlatformMovementMode
{
	LeftRight,
	UpDown
}

class USolarFlareHoverPlatformComponent : UActorComponent
{
	ESolarFlareHoverPlatformMovementMode MovementMode;
	ASolarFlareHoverPlatform Platform;
	bool bActivated;

	void ActivatePlatform()
	{

	}
}