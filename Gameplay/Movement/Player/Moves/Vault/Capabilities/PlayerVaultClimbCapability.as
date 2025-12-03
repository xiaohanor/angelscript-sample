/*
	Vaults the player ontop of the ledge, if the ledge is too long to vault over
*/
class UPlayerVaultClimbCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Vault);
	default CapabilityTags.Add(PlayerVaultTags::VaultClimb);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;
	default TickGroupSubPlacement = 5;

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UTeleportingMovementData Movement;

	UPlayerMovementComponent MoveComp;
	UPlayerVaultComponent VaultComp;
	UPlayerSprintComponent SprintComp;

	float MoveSpeed = 0.0;
	bool bMoveComplete = false;

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
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!VaultComp.Data.HasValidData())
			return false;

		if (!VaultComp.Data.bEnterComplete)
			return false;

		if (VaultComp.Data.Mode != EPlayerVaultMode::Climb)
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

		FVector ToEnd = VaultComp.Data.EndLocation - Player.ActorLocation;
		FVector ToEndFlattened = ToEnd.ConstrainToPlane(MoveComp.WorldUp);
		float MoveDuration = ToEndFlattened.Size() / VaultComp.Data.EnterSpeed;
		MoveSpeed = ToEnd.Size() / MoveDuration;

		VaultComp.SetState(EPlayerVaultState::Climb);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Vault, this);

		VaultComp.StateCompleted(EPlayerVaultState::Climb);

		VaultComp.Data.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			FVector ToEnd = VaultComp.Data.EndLocation - Player.ActorLocation;
			FVector DeltaMove = ToEnd.GetSafeNormal() * MoveSpeed * DeltaTime;
			if (ToEnd.Size() < DeltaMove.Size())
			{
				DeltaMove = ToEnd;
				bMoveComplete = true;
				Movement.OverrideFinalGroundResult(VaultComp.Data.VaultExitFloorHit);
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
	}
}