class USummitTeenDragonRollLauncherDragCapability : UInteractionCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;

	ASummitTeenDragonRollLauncher Launcher;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		
		Launcher = Cast<ASummitTeenDragonRollLauncher>(Params.Interaction.Owner);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		if(Launcher.Camera != nullptr)
			Player.ActivateCamera(Launcher.Camera, 0.5, this);

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		Launcher.StartPulling();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if(Launcher.Camera != nullptr)
			Player.DeactivateCamera(Launcher.Camera, 0.5);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		
		Launcher.StopPulling();

		RollComp.bHasBeenLaunched = true;
		// RollComp.bIsRolling = true;
		float LaunchSpeed = Launcher.MaxLaunchSpeed * Launcher.GetPullAlpha();
		FVector LaunchVelocity = Launcher.PullRoot.ForwardVector * LaunchSpeed;
		Player.SetActorVelocity(LaunchVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Input = MoveComp.MovementInput;

				float InputDotLauncher = Input.DotProduct(Launcher.PullRoot.ForwardVector);

				float MaxMoveSpeed = InputDotLauncher < 0 
					? Launcher.PullBackSpeed
					: Launcher.PullForwardSpeed;
				
				float DeltaMoveSpeed = InputDotLauncher * MaxMoveSpeed * DeltaTime;
				Launcher.Move(-DeltaMoveSpeed);

				FVector TargetPos = Launcher.PullRoot.WorldLocation;
				Movement.AddDelta(TargetPos - Player.ActorLocation);
				Movement.SetRotation(Launcher.PullRoot.WorldRotation);
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TaillTeenPull);
		}
	}
}