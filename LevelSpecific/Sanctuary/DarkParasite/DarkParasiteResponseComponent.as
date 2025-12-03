event void FDarkParasiteFocusSignature(AHazePlayerCharacter Instigator, FDarkParasiteTargetData TargetData);
event void FDarkParasiteAttachSignature(AHazePlayerCharacter Instigator, FDarkParasiteTargetData TargetData);
event void FDarkParasiteGrabSignature(AHazePlayerCharacter Instigator, FDarkParasiteTargetData AttachedData, FDarkParasiteTargetData GrabbedData);

class UDarkParasiteResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	FDarkParasiteFocusSignature OnFocused;
	FDarkParasiteFocusSignature OnUnfocused;
	FDarkParasiteAttachSignature OnAttached;
	FDarkParasiteAttachSignature OnDetached;
	FDarkParasiteGrabSignature OnGrabbed;
	FDarkParasiteGrabSignature OnReleased;

	void Focus(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		OnFocused.Broadcast(Instigator, TargetData);
	}

	void Unfocus(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		OnUnfocused.Broadcast(Instigator, TargetData);
	}

	void Attach(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		OnAttached.Broadcast(Instigator, TargetData);
	}

	void Detach(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		OnDetached.Broadcast(Instigator, TargetData);
	}

	void Grab(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData GrabbedData)
	{
		OnGrabbed.Broadcast(Instigator, AttachedData, GrabbedData);
	}

	void Release(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData GrabbedData)
	{
		OnReleased.Broadcast(Instigator, AttachedData, GrabbedData);
	}
}