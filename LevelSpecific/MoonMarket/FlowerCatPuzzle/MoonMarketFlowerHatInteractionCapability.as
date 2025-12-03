class UMoonMarketFlowerHatInteractionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerInteractionsComponent InteractionComp;
	UMoonMarketPlayerFlowerSpawningComponent FlowerComp;
	UHazeMovementComponent MoveComp;

	bool bAttachedToHand = false;
	bool bAttachedToHead = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractionComp = UPlayerInteractionsComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		FlowerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FlowerComp.bPickingUpHat)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > FlowerComp.InteractionAnimation.PlayLength - 1.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FlowerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(Player);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.PlaySlotAnimation(FlowerComp.InteractionAnimation);

		bAttachedToHand = false;
		bAttachedToHead = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.StopSlotAnimation();
		FlowerComp.bPickingUpHat = false;
		
		if(FlowerComp.Hat != nullptr)
		{
			FlowerComp.Hat.SetActorRelativeLocation(FVector::UpVector * 10);
			FlowerComp.Hat.SetActorRelativeRotation(FRotator::ZeroRotator);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bAttachedToHand && ActiveDuration >= 0.6)
		{
			bAttachedToHand = true;
			FlowerComp.Hat.AttachToComponent(Player.Mesh, n"RightHand", EAttachmentRule::KeepWorld);
		}

		if(!bAttachedToHead && ActiveDuration >= 0.89)
		{
			bAttachedToHead = true;
			Player.PlayForceFeedback(ForceFeedback::Default_Light_Tap, false, false, this, 0.5);
			FlowerComp.Hat.AttachToComponent(Player.Mesh, n"Head", EAttachmentRule::KeepWorld);
		}

		if(bAttachedToHead)
		{
			FlowerComp.Hat.SetActorRelativeLocation(Math::VInterpTo(FlowerComp.Hat.ActorRelativeLocation, FVector::UpVector * 10, DeltaTime, 15));
			FlowerComp.Hat.SetActorRelativeRotation(Math::RInterpTo(FlowerComp.Hat.ActorRelativeRotation, FRotator::ZeroRotator, DeltaTime, 10));
		}
		else if(bAttachedToHand)
		{
			FVector TargetRelativeLocation = FlowerComp.Hat.ActorRelativeLocation;
			TargetRelativeLocation.Z = 0;
			FlowerComp.Hat.SetActorRelativeLocation(Math::VInterpTo(FlowerComp.Hat.ActorRelativeLocation, TargetRelativeLocation, DeltaTime, 10));
			FlowerComp.Hat.SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, FlowerComp.Hat.ActorForwardVector));
		}
	}
};