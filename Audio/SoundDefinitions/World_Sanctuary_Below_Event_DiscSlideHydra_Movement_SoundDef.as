
UCLASS(Abstract)
class UWorld_Sanctuary_Below_Event_DiscSlideHydra_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	bool bUseMovementLoop = false;

	ADiscSlideHydra Hydra;
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Hydra = Cast<ADiscSlideHydra>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Make sure we only activate when needed.
		ActivateMovementLoop();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Always kill loops on deactivate.
		DeactivateMovementLoop();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (!bUseMovementLoop)
			return;

		// We can combine the players closest position on the mesh,
		// They will both be on the disc, so there is no difference that
		// can be heard.

		const auto AllSockets = Hydra.SkeletalMesh.GetAllSocketNames();
		
		FVector NewPosition;
		float ClosestDistance = MAX_flt;
		auto PlayerPosition = Game::Mio.ActorLocation;

		for (const auto& SocketName: AllSockets)
		{
			auto Position = Hydra.SkeletalMesh.GetSocketLocation(SocketName);
			auto Distance = Position.DistSquared(PlayerPosition);
			if (Distance > 0 && Distance < ClosestDistance)
			{
				NewPosition = Position;
				ClosestDistance = Distance;
			}
		}
		
		DefaultEmitter.GetAudioComponent().WorldLocation = NewPosition;
	}

	UFUNCTION(BlueprintEvent)
	void ActivateMovementLoop()
	{

	}

	UFUNCTION(BlueprintEvent)
	void DeactivateMovementLoop()
	{

	}
}