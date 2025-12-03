struct FMoonMarketLanternInteractionActivationParams
{
	AMoonMarketRevealingLantern Lantern;
}

class UMoonMarketLanternInteractionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerInteractionsComponent InteractionComp;
	UMoonMarketLanternInteractionComponent LanternComp;

	bool bAttachedToHand = false;
	bool bAttachedToHip = false;

	AMoonMarketRevealingLantern Lantern;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LanternComp = UMoonMarketLanternInteractionComponent::Get(Player);
		InteractionComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMoonMarketLanternInteractionActivationParams& Params) const
	{
		if(!LanternComp.bPickingUpLantern)
			return false;

		if(LanternComp.Lantern == nullptr)
			return false;

		Params.Lantern = LanternComp.Lantern;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > LanternComp.PickupAnim.PlayLength)
			return true;

		if(Lantern == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMoonMarketLanternInteractionActivationParams Params)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.PlaySlotAnimation(LanternComp.PickupAnim);
		Player.SetActorRotation((Params.Lantern.ActorLocation - Player.ActorLocation).VectorPlaneProject(FVector::UpVector).Rotation());

		Lantern = Params.Lantern;
		bAttachedToHand = false;
		bAttachedToHip = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.StopSlotAnimation();
		LanternComp.bPickingUpLantern = false;

		if(Lantern != nullptr)
		{
			UMoonMarketRevealingLanternEventHandler::Trigger_OnPickup(Lantern);

			if(!bAttachedToHip)
			{
				Lantern.AttachToComponent(Player.Mesh, n"MoonMarketLanternSocket", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
				Lantern.SetActorRelativeRotation(FRotator::ZeroRotator);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bAttachedToHand && ActiveDuration >= 0.3)
		{
			bAttachedToHand = true;
			Lantern.AttachToComponent(Player.Mesh, n"RightAttach", EAttachmentRule::KeepWorld);
		}

		if(!bAttachedToHip && ActiveDuration >= 0.7)
		{
			bAttachedToHip = true;
			Lantern.AttachToComponent(Player.Mesh, n"MoonMarketLanternSocket", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			Player.PlayForceFeedback(LanternComp.Rumble, false, false, this);
		}

		if(bAttachedToHip)
		{
			Lantern.SetActorRelativeRotation(Math::RInterpTo(Lantern.ActorRelativeRotation, FRotator::ZeroRotator, DeltaTime, 2));
		}
		else if(bAttachedToHand)
		{
			//LanternComp.Lantern.SetActorRotation(FQuat::MakeFromZX(FVector::UpVector, LanternComp.Lantern.ActorForwardVector).Rotator());
			//LanternComp.Lantern.SetActorRotation(Math::RInterpTo(LanternComp.Lantern.ActorRotation, FQuat::MakeFromXZ(LanternComp.Lantern.ActorForwardVector, FVector::UpVector).Rotator(), DeltaTime, 2));
		}
	}
};