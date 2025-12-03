/*
	Gets the player to the near edge
	Splits into Climb, Vault Exit or Slide
*/
class UPlayerVaultEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Vault);
	default CapabilityTags.Add(PlayerVaultTags::VaultEnter);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;
	default TickGroupSubPlacement = 10;

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UTeleportingMovementData Movement;

	UPlayerMovementComponent MoveComp;
	UPlayerVaultComponent VaultComp;
	UPlayerSprintComponent SprintComp;

	float MoveSpeed = 0.0;
	FVector EndLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		VaultComp = UPlayerVaultComponent::GetOrCreate(Owner);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Owner);

		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerVaultData& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (VaultComp.Data.bEnterComplete)
			return false;
		
		FVector VaultDirection;
		if (!MoveComp.HorizontalVelocity.IsNearlyZero())
			VaultDirection = MoveComp.HorizontalVelocity.GetSafeNormal();
		else if (!MoveComp.MovementInput.IsNearlyZero())
			VaultDirection = MoveComp.MovementInput.GetSafeNormal();
		else
			return false;

		FPlayerVaultData VaultData;
		if (!VaultComp.TraceForVault(Player, VaultDirection, VaultData))
			return false;

		ActivationParams = VaultData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (VaultComp.Data.bEnterComplete)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerVaultData ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(BlockedWhileIn::Vault, this);

		VaultComp.Data = ActivationParams;
		VaultComp.Data.bEnteredInSprint = SprintComp.IsSprinting();
		VaultComp.SetState(EPlayerVaultState::Enter);
		
		EndLocation = VaultComp.Data.NearEdgeLocation - (MoveComp.WorldUp * Player.CapsuleComponent.CapsuleHalfHeight);
		FVector ToEnd = EndLocation - Player.ActorLocation;
		MoveSpeed = ToEnd.Size() / VaultComp.Data.EnterDuration;

		VaultComp.AnimData.EnterDistanceSpeed = FVector2D(VaultComp.Data.EnterDistance, VaultComp.Data.EnterSpeed);
		VaultComp.AnimData.bEnterFinished = false;

		//Mirror the animation based on vault direction and screen forward
		float VaultDirScreenDot = VaultComp.Data.Direction.CrossProduct(MoveComp.WorldUp).DotProduct(Player.ViewRotation.ForwardVector);
		VaultComp.AnimData.bIsMirrored = VaultDirScreenDot > 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(BlockedWhileIn::Vault, this);

		VaultComp.StateCompleted(EPlayerVaultState::Enter);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			FVector ToEnd = EndLocation - Player.ActorLocation;
			FVector DeltaMove = ToEnd.GetSafeNormal() * MoveSpeed * DeltaTime;
			if (ToEnd.Size() < DeltaMove.Size())
			{
				DeltaMove = ToEnd;
				VaultComp.Data.bEnterComplete = true;
				VaultComp.AnimData.bEnterFinished = true;
			}
			
			Movement.AddDeltaWithCustomVelocity(DeltaMove, VaultComp.Data.Direction * VaultComp.Data.EnterSpeed);
			Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, FRotator::MakeFromXZ(VaultComp.Data.Direction, MoveComp.WorldUp), DeltaTime, 900.0));
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
			//Movement.ApplyCrumbSyncedAirMovement();
		}
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Vault");
	}
}