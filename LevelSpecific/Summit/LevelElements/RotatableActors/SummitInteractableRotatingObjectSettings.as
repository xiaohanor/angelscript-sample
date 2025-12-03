class USummitInteractableRotatingObjectSettings : UHazeComposableSettings
{
	// The speed at which it rotates
	UPROPERTY()
	float RotationSpeed = 20;

	// The offset from the object the dragon gets attached to
	UPROPERTY()
	float InteractionAttachmentOffset = 400;

	// Amount of seconds it takes for the dragon to "teleport" to the interaction point
	UPROPERTY()
	float InteractionTeleportDuration = 0.75;
}