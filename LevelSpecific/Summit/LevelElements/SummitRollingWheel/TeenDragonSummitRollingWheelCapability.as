class UTeenDragonSummitRollingWheelCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitRollingWheel RollingWheel;

	UPlayerTailTeenDragonComponent DragonComp;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UTeenDragonRollSettings RollSettings;

	bool bRollingForward = true;

	float LastRollPosition = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		UCameraSettings::GetSettings(Player).FOV.Apply(66.0, this, 2, EHazeCameraPriority::Low);

		RollingWheel = Cast<ASummitRollingWheel>(Params.Interaction.Owner);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		if (RollingWheel.Camera != nullptr)
			Player.ActivateCamera(RollingWheel.Camera, 2.0, this);

		if (RollingWheel.ActorForwardVector.DotProduct(Player.ActorForwardVector) > 0.0)
			bRollingForward = true;
		else
			bRollingForward = false;

		RollingWheel.SyncedCurrentRollPosition.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this);
		MoveComp.FollowComponentMovement(RollingWheel.Root, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Interaction);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		
		Player.ClearCameraSettingsByInstigator(this, 2.0);

		if (RollingWheel.Camera != nullptr)
			Player.DeactivateCamera(RollingWheel.Camera, 2.0);

		DragonComp.AnimationState.Clear(this);
		RollingWheel.SpinVelocity = 0.0;

		RollingWheel.SyncedCurrentRollPosition.OverrideSyncRate(EHazeCrumbSyncRate::Low);

		Player.SetActorVelocity(FVector::ZeroVector);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if (!MoveComp.MovementInput.IsNearlyZero())
				{
					float InputDot = RollingWheel.ActorForwardVector.DotProduct(MoveComp.MovementInput);
					if (InputDot > 0.0)
						bRollingForward = true;
					else
						bRollingForward = false;
				}

				FRotator WheelRotation = FRotator::MakeFromX(RollingWheel.ActorForwardVector);
				if (!bRollingForward)
					WheelRotation = FRotator::MakeFromX(-RollingWheel.ActorForwardVector);

				float CurrentRollSpeed = RollSettings.RollStartSpeed * MoveComp.MovementInput.Size();
				Movement.AddDeltaWithCustomVelocity(FVector::ZeroVector, WheelRotation.ForwardVector * CurrentRollSpeed);


				FQuat Rotation = Math::QInterpConstantTo(
					Player.ActorQuat,
					WheelRotation.Quaternion(),
					DeltaTime,
					4.0 * PI
				);
				Movement.SetRotation(Rotation);

				if (ActiveDuration > RollSettings.RollWindUpTime)
				{
					float RollAmount = DeltaTime * CurrentRollSpeed;
					if (bRollingForward)
						RollAmount *= -1.0;


					RollingWheel.ApplyRoll(RollAmount);
					RollingWheel.SpinVelocity = RollAmount / DeltaTime;
					RollingWheel.SyncedCurrentRollPosition.Value = RollingWheel.CurrentRollPosition;
				}
			}
			// Remote
			else
			{
				float RollAmount = RollingWheel.SyncedCurrentRollPosition.Value - LastRollPosition;
				RollingWheel.SpinVelocity = RollAmount / DeltaTime;
				RollingWheel.ApplyRoll(RollAmount);
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			LastRollPosition = RollingWheel.CurrentRollPosition;

			if (MoveComp.HorizontalVelocity.Size() > 1.0)
				DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRoll, this, EInstigatePriority::Interaction);
			else
				DragonComp.AnimationState.Apply(ETeenDragonAnimationState::FloorMovement, this, EInstigatePriority::Interaction);

			MoveComp.ApplyMove(Movement);
			FName LocomotionTag = TeenDragonLocomotionTags::RollMovement;
			if(MoveComp.MovementInput.IsNearlyZero())
				LocomotionTag = TeenDragonLocomotionTags::Movement;
			DragonComp.RequestLocomotionDragonAndPlayer(LocomotionTag);
		}
	}
};