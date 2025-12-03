class UPlayerVaultSlideCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Vault);
	default CapabilityTags.Add(PlayerVaultTags::VaultSlide);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;
	default TickGroupSubPlacement = 5;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UTeleportingMovementData Movement;

	UPlayerMovementComponent MoveComp;
	UPlayerVaultComponent VaultComp;

	float MoveSpeed = 0.0;
	bool bMoveComplete = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		VaultComp = UPlayerVaultComponent::GetOrCreate(Owner);
		
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!VaultComp.Data.HasValidData())
			return false;

		if (!VaultComp.Data.bEnterComplete)
			return false;

		if (VaultComp.Data.Mode != EPlayerVaultMode::Slide)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return bMoveComplete;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Vault, this);

		bMoveComplete = false;

		FVector ToEndLocation = VaultComp.Data.FarEdgePlayerLocation - Player.ActorLocation;
		FVector ToEndFlattened = ToEndLocation.ConstrainToPlane(MoveComp.WorldUp);
		float MoveDuration = ToEndFlattened.Size() / VaultComp.Data.EnterSpeed;
		MoveSpeed = ToEndLocation.Size() / MoveDuration;

		VaultComp.SetState(EPlayerVaultState::Slide);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Vault, this);
		VaultComp.StateCompleted(EPlayerVaultState::Slide);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			const FVector ToEndLocation = VaultComp.Data.FarEdgePlayerLocation - Player.ActorLocation;
			FVector DeltaMove = ToEndLocation.GetSafeNormal() * MoveSpeed * DeltaTime;
			if (ToEndLocation.Size() < DeltaMove.Size())
			{
				DeltaMove = ToEndLocation;
				bMoveComplete = true;
				VaultComp.Data.bSlideComplete = true;
			}

			Movement.AddDeltaWithCustomVelocity(DeltaMove, VaultComp.Data.Direction * VaultComp.Data.EnterSpeed);
			Movement.SetRotation(Owner.ActorRotation);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
			//Movement.ApplyCrumbSyncedAirMovement();
		}
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Vault");

		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * 30.0) * 0.4;
		FF.RightMotor = Math::Sin(-ActiveDuration * 30.0) * 0.4;
		Player.SetFrameForceFeedback(FF);
	}
}