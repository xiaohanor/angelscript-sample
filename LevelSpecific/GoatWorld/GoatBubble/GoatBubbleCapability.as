class UGoatBubbleCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;
	FHazeAcceleratedRotator AccRotation;

	UGoatBubblePlayerComponent BubbleComp;
	UGenericGoatPlayerComponent GoatComp;

	AGoatBubbleActor CurrentBubble;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		BubbleComp = UGoatBubblePlayerComponent::Get(Player);
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		if (ActiveDuration >= 2.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRotation.SnapTo(Owner.ActorRotation);	

		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		CurrentBubble = SpawnActor(BubbleComp.BubbleClass, Player.ActorLocation, Player.ActorRotation);
		CurrentBubble.AttachToActor(GoatComp.CurrentGoat);

		FHitResult DummyHit;
		CurrentBubble.SetActorRelativeLocation(FVector(0.0, 0.0, 120.0), false, DummyHit, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);

		CurrentBubble.DestroyBubble();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(Player.HasControl())
		{
			FVector FwdAcc = Player.ViewRotation.ForwardVector * GetAttributeFloat(AttributeNames::MoveForward) * 1000.0;
			FVector RightAcc = Player.ViewRotation.RightVector * GetAttributeFloat(AttributeNames::MoveRight) * 1000.0;
			FVector UpAcc = FVector::UpVector * 800.0;

			FVector Velocity = MoveComp.Velocity;
			Velocity += (FwdAcc + RightAcc + UpAcc) * DeltaTime;
			Velocity -= Velocity * 1.2 * DeltaTime;

			AccRotation.Value = Owner.ActorRotation;  // In case something else has rotated us
			AccRotation.AccelerateTo(Player.ViewRotation, 0.5, DeltaTime);
			Movement.SetRotation(AccRotation.Value);

			Movement.AddVelocity(Velocity);
			MoveComp.ApplyMove(Movement);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			Movement.ApplyCrumbSyncedAirMovement();
		}

		/*if (ActiveDuration >= 10.0)
		{
			if (Bot != nullptr)
				Bot.RemoteHackingResponseComp.SetHackingAllowed(false);
		}*/
	}
}