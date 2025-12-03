/**
 * Logs some standard values about the player to the temporal log every frame.
 */
class UPlayerGlobalTemporalLogCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterPhysics;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
#if EDITOR
		UMovementInstigatorLogComponent::GetOrCreate(Player);
		if (Player.IsMio())
			UTimeDilationComponent::GetOrCreate(Player);
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if !RELEASE
		// Write some basic information about the player the temporal log
		auto TemporalLog = TEMPORAL_LOG(Player);

		auto PositionSection = TemporalLog.Page("Position");

		PositionSection.Section("World")
			.Transform("Transform", Player.ActorTransform)
			.Capsule("Capsule",
				Player.CapsuleComponent.WorldLocation,
				Player.CapsuleComponent.ScaledCapsuleRadius,
				Player.CapsuleComponent.ScaledCapsuleHalfHeight,
				Player.CapsuleComponent.WorldRotation,
				FLinearColor::Blue)
			.Transform("Mesh Transform", Player.Mesh.WorldTransform)
		;

		if(Player.AttachParentActor != nullptr)
		{
			PositionSection.Section("Attachment")
				.Transform("Relative Transform", Player.ActorRelativeTransform)
				.Value("AttachParent Actor", Player.AttachParentActor)
				.Value("AttachParent Component", Player.RootComponent.AttachParent)
				.Value("AttachParent SocketName", Player.AttachParentSocketName)
				.Transform("AttachParent ActorTransform", Player.AttachParentActor.ActorTransform)
			;
		}
#endif
	}
};