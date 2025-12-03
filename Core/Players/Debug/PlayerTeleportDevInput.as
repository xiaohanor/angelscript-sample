
class UPlayerTeleportOtherToMeDevInput : UHazeDevInputHandler
{
	default Name = n"Teleport Other Player to Me";
	default Category = n"Default";

	default AddKey(EKeys::Gamepad_FaceButton_Left);
	default AddKey(EKeys::Q);

	default DisplaySortOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		PlayerOwner.OtherPlayer.TeleportActor(
			PlayerOwner.ActorLocation,
			PlayerOwner.ActorRotation,
			n"TeleportOtherPlayerToMe"
		);
	}
}

class UPlayerTeleportToOtherDevInput : UHazeDevInputHandler
{
	default Name = n"Teleport to Other Player";
	default Category = n"Default";

	default AddKey(EKeys::Gamepad_RightThumbstick);
	default AddKey(EKeys::R);

	default DisplaySortOrder = 101;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		PlayerOwner.TeleportActor(
			PlayerOwner.OtherPlayer.ActorLocation,
			PlayerOwner.OtherPlayer.ActorRotation,
			n"TeleportToOtherPlayer"
		);
	}
}