class ADarkMassActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	TArray<UTargetableComponent> CurrentGrabs;
	FDarkMassSurfaceData CurrentSurface; // Misnomer with new usage

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Debug::DrawDebugLine(ActorLocation, CurrentSurface.WorldLocation);
		Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, 100.0, 5.0);
	}

	bool AttachToSurface()
	{
		if (!CurrentSurface.IsValid())
			return false;

		DetachFromSurface();
		SetActorLocationAndRotation(
			CurrentSurface.WorldLocation,
			FRotator::MakeFromX(CurrentSurface.WorldNormal)
		);
		AttachToComponent(CurrentSurface.SurfaceComponent, CurrentSurface.SocketName, EAttachmentRule::KeepWorld);
		return true;
	}

	bool DetachFromSurface()
	{
		if (Root.AttachParent != nullptr && 
			Root.AttachParent != CurrentSurface.SurfaceComponent)
		{
			devError("We're attached to something other than the current surface, we'll detach but not call events.");
			DetachRootComponentFromParent(true);
			return false;
		}

		if (Root.AttachParent == nullptr)
			return false;
		
		DetachRootComponentFromParent(true);
		return true;
	}
}