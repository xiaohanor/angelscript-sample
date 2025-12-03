class URemoteHackingPlayerActiveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"ExoSuit");
	default CapabilityTags.Add(n"RemoteHackingActive");
	
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	URemoteHackingPlayerComponent HackingPlayerComp;
	UHazeMovementComponent MoveComp;

	bool bDeathBlocked = true;
	bool bGameplayBlocked = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackingPlayerComp = URemoteHackingPlayerComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HackingPlayerComp.bHackActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HackingPlayerComp.bHackActive)
			return true;

		if (!HackingPlayerComp.CurrentHackingResponseComp.bAllowHacking)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AttachToComponent(HackingPlayerComp.CurrentHackingResponseComp, NAME_None, EAttachmentRule::KeepWorld);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		Player.BlockCapabilities(n"PlayerShadow", this);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);

		if (HackingPlayerComp.CurrentHackingResponseComp.bBlockGameplayAction)
		{
			bGameplayBlocked = true;
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		}
		else
			bGameplayBlocked = false;

		if (!HackingPlayerComp.CurrentHackingResponseComp.bCanDie)
		{
			bDeathBlocked = true;
			Player.BlockCapabilities(n"Death", this);
			Player.AddDamageInvulnerability(this);
		}
		else
			bDeathBlocked = false;

		if (HackingPlayerComp.CurrentHackingResponseComp.bCanCancel)
			Player.ShowCancelPrompt(this);

		Player.SmoothTeleportActor(Player.ActorLocation, HackingPlayerComp.CurrentHackingResponseComp.WorldRotation, this);

		Player.ResetAirDashUsage();
		Player.ResetAirJumpUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);

		if (bGameplayBlocked)
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if (bDeathBlocked)
		{
			Player.UnblockCapabilities(n"Death", this);
			Player.RemoveDamageInvulnerability(this);
		}

		Player.RemoveCancelPromptByInstigator(this);

		Player.StopSlotAnimation();

		Player.DetachFromActor();

		Player.ClearMovementInput(this);

		HackingPlayerComp.StopHacking();

		if (HackingPlayerComp.CurrentHackingResponseComp != nullptr)
		{
			if (HackingPlayerComp.CurrentHackingResponseComp.bResetMovementOnExit)
				Player.ResetMovement();

			if (HackingPlayerComp.CurrentHackingResponseComp.ExitLaunchForce != FVector::ZeroVector)
			{
				FVector LocalLaunchForce = HackingPlayerComp.CurrentHackingResponseComp.ExitLaunchForce;
				FVector WorldForce = HackingPlayerComp.CurrentHackingResponseComp.ForwardVector * LocalLaunchForce.X;
				WorldForce += HackingPlayerComp.CurrentHackingResponseComp.RightVector * LocalLaunchForce.Y;
				WorldForce.Z= LocalLaunchForce.Z;
				Player.AddMovementImpulse(WorldForce, n"HackingExit");
			}

			auto HackingTargetActor = Cast<AHazeActor>(HackingPlayerComp.CurrentHackingResponseComp.GetOwner());
			URemoteHackingEventHandler::Trigger_OnHackingStopped(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector MoveInput = FVector(MovementRaw.X, MovementRaw.Y, 0.0);

		const FVector WorldUp = MoveComp.WorldUp;

		const float MoveInputSize = MoveInput.Size();
		MoveInput = Player.ViewTransform.Rotation.RotateVector(MoveInput).VectorPlaneProject(WorldUp).GetSafeNormal();
		MoveInput *= MoveInputSize;

		Player.ApplyMovementInput(MoveInput, this);
	}
}