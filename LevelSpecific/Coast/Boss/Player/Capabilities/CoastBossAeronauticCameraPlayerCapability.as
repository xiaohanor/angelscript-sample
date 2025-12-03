asset CoastBossAeronauticOrbitBlend of UCameraOrbitBlend
{
	
}

asset CoastBossAeronauticKeepVelocityBlend of UCameraDefaultBlend
{
	bIncludeLocationVelocity = true;
}

class UCoastBossAeronauticCameraPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	ACoastBossActorReferences References;
	UCoastBossAeronauticComponent AirMoveDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AirMoveDataComp = UCoastBossAeronauticComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (References == nullptr)
			return false;
		if (References.Camera == nullptr)
			return false;
		if (!AirMoveDataComp.bAttached)
			return false;
		if (AirMoveDataComp.bShouldPlayerEnter && !AirMoveDataComp.bCameraShouldBlendInFromEnter)
			return false;
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
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		if(AirMoveDataComp.bShouldPlayerEnter)
			Player.ActivateCameraCustomBlend(References.Camera, CoastBossAeronauticOrbitBlend, 2.0, this);
		else
			Player.ActivateCamera(References.Camera, 0.0, this);
		
		//I added instant fullscreen here instead of blend with projection offset, because if we come from natural progression on the train, we already have fullscreen set, and if we come from progresspoint, we want instant fullscreen //Per
		//Seems like the split screen is visible for a little bit anyway though //Per
		if (Player.IsMio())
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		// 	Camera::BlendToFullScreenUsingProjectionOffset(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.DeactivateCamera(References.Camera, 2.0);
		if (Player.IsMio())
			Camera::BlendToSplitScreenUsingProjectionOffset(this);
	}
};