class UTeenDragonHamsterWheelRollingCapability : UInteractionCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitHamsterWheel HamsterWheel;

	UPlayerTailTeenDragonComponent DragonComp;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		HamsterWheel = Cast<ASummitHamsterWheel>(Params.Interaction.Owner);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		if (HamsterWheel.Camera != nullptr)
			Player.ActivateCamera(HamsterWheel.Camera, 2.0, this);

		HamsterWheel.SyncedCurrentRollPosition.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this);
		MoveComp.FollowComponentMovement(HamsterWheel.Root, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Interaction);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		
		Player.ClearCameraSettingsByInstigator(this, 2.0);

		if (HamsterWheel.Camera != nullptr)
			Player.DeactivateCamera(HamsterWheel.Camera, 2.0);

		DragonComp.AnimationState.Clear(this);

		HamsterWheel.SyncedCurrentRollPosition.OverrideSyncRate(EHazeCrumbSyncRate::Low);

		Player.SetActorVelocity(FVector::ZeroVector);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(IsActioning(ActionNames::PrimaryLevelAbility))
				{
					FVector Move = HamsterWheel.ActorForwardVector * HamsterWheel.RollSpeed;
					Movement.AddHorizontalVelocity(Move);
				}
			}
			else
			{	
				Movement.ApplyCrumbSyncedGroundMovement();
			}
		}

		MoveComp.ApplyMove(Movement);
		FName LocomotionTag = TeenDragonLocomotionTags::RollMovement;
		if(MoveComp.MovementInput.IsNearlyZero())
			LocomotionTag = TeenDragonLocomotionTags::Movement;
		DragonComp.RequestLocomotionDragonAndPlayer(LocomotionTag);
	}
};