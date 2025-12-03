
UCLASS(Abstract)
class UWorld_Tundra_MonkeyRealm_Platform_River_GeyserPlatform_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPlatformFall(){}

	UFUNCTION(BlueprintEvent)
	void OnPlatformRise(){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlammed(){}

	/* END OF AUTO-GENERATED CODE */

	UTundraPlayerOtterSwimmingComponent OtterSwimComp;
	
	const float CAMERA_BELOW_SURFACE_VERTICAL_BUFFER_DISTANCE = -30.0;

	AHazePlayerCharacter Mio;

	private ATundra_River_GeyserPlatform GeyserPlatform;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Mio = Game::GetMio();
		GeyserPlatform = Cast<ATundra_River_GeyserPlatform>(HazeOwner);
		GeyserPlatform.ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerLand");
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLand(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Camera is below surface"))
	bool GetCameraIsBelowSurface()
	{
		if(!EnsureSwimComp())		
			return false;		

		FTundraPlayerOtterSwimmingSurfaceData Data;
		if (!OtterSwimComp.CheckForSurface(Mio, Data))
			return false;

		// Compare camera and surface world location on z axis, to see if camera is under surface of swimming volume		
		ASwimmingVolume Volume = Data.SwimmingVolume;
		const FVector VolumeTop = Volume.GetActorLocation() + (FVector::UpVector * Volume.BrushComponent.BoundsExtent.Z);

		// Camera in water!
		if(VolumeTop.Z > (Mio.GetViewLocation().Z + CAMERA_BELOW_SURFACE_VERTICAL_BUFFER_DISTANCE))
			return true;
	
		return false;
	}

	bool EnsureSwimComp()
	{
		if(OtterSwimComp == nullptr)		
			OtterSwimComp = UTundraPlayerOtterSwimmingComponent::Get(Mio);

		return OtterSwimComp != nullptr;		
	}

}