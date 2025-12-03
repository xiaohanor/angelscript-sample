class UPlayerChestTurnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketMimicPlayerComponent LaunchComp;
	float RotationSpeed = 80.0;
	FHazeAcceleratedFloat AccelFloat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchComp = UMoonMarketMimicPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LaunchComp.bLaunchReady)
			return false;

		if(LaunchComp.CurrentMimic == nullptr)
			return false;

		if(LaunchComp.CurrentMimic.bIsPlayerMimic)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LaunchComp.bLaunchReady)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector Offset = LaunchComp.CurrentMimic.ActorForwardVector * 100.0;
		Offset += LaunchComp.CurrentMimic.ActorUpVector * 20.0;
		Player.AttachToActor(LaunchComp.CurrentMimic, NAME_None, EAttachmentRule::KeepWorld);
		Player.TeleportActor(LaunchComp.CurrentMimic.ActorLocation + Offset, LaunchComp.CurrentMimic.ActorRotation, this, false);

		LaunchComp.CurrentMimic.BP_PlayReadyTimeline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float YRot = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;
		AccelFloat.AccelerateTo(YRot, 0.2, DeltaTime);
		LaunchComp.CurrentMimic.AddActorLocalRotation(FRotator(0.0, AccelFloat.Value * RotationSpeed * DeltaTime, 0.0));
	}
};