class UAdultDragonStrafeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UAdultDragonStrafeSettings StrafeSettings;
	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonStrafeComponent StrafeComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
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
		Player.ApplyCameraSettings(StrafeComp.StrafeCameraSettings, StrafeSettings.CameraBlendInTime, this, SubPriority = 62);
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this);
		Player.PlayCameraShake(DragonComp.ConstantShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, StrafeSettings.CameraBlendOutTime);
		Player.StopCameraShakeByInstigator(this);
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StrafeComp.Velocity = MoveComp.Velocity;
		StrafeComp.Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		if(SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
		{
			// Note (David): This updates the splineposition which is used to change splines
			SplineFollowManagerComp.UpdateInternalSplinePosition(DeltaTime);

			//FAdultDragonSplineFollowData Data = SplineFollowManagerComp.UpdateInternalSplinePosition(DeltaTime);
			
			// // While we are in strafe mode, we override the respawn to be next to the other player
			// FTransform SplineTransform = Data.SplinePos.WorldTransform;
			// SplineTransform = SplineTransform.GetRelativeTransform(Player.ActorTransform);
			// const FVector Forward = SplineTransform.Rotation.ForwardVector;
			
			// // If the spline is to far away, just respawn at the player location
			// if(SplineTransform.Location.SizeSquared() > Math::Square(5000))
			// 	SplineTransform = FTransform::Identity;
			
			// // always spawn a bit behind the other player so we get a feeling for where we are going
			// SplineTransform.AddToTranslation(-Forward * 3000);

			// Player.OtherPlayer.ApplyRespawnPointOverrideLocation(this, SplineTransform, Player.RootComponent);
			// // Player.OtherPlayer.BlockCapabilities(n"Respawn", this);
		}
	}
} 