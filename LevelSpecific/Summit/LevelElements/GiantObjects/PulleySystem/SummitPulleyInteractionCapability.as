class USummitPulleyInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	APulleyInteraction PulleyInteraction;

	UPlayerTailTeenDragonComponent DragonComp;
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	USummitPulleySettings PulleySettings;

	float ExitTimer = 0.0;
	float ExitDuration = 0.0;
	bool bIsExiting = false;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		PulleyInteraction = Cast<APulleyInteraction>(Params.Interaction.Owner);
		PulleySettings = USummitPulleySettings::GetSettings(PulleyInteraction);
		
		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this, 0.75);
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);

		PulleyInteraction.EnterInteraction();

		if(PulleyInteraction.PulleyCamera != nullptr)
			Player.ActivateCamera(PulleyInteraction.PulleyCamera, PulleySettings.CameraBlendInTime, this);

		Player.SetActorVelocity(FVector::ZeroVector);

		ExitTimer = 0.0;
		bIsExiting = false;

		Player.BlockCapabilities(n"InteractionCancel", this);

		PulleyInteraction.InteractComp.SetPlayerIsAbleToCancel(Player, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		if(PulleyInteraction.PulleyCamera != nullptr)
			Player.DeactivateCamera(PulleyInteraction.PulleyCamera, PulleySettings.CameraBlendInTime);

		Player.SetActorVelocity(FVector::ZeroVector);

		Player.UnblockCapabilities(n"InteractionCancel", this);
		PulleyInteraction.InteractComp.SetPlayerIsAbleToCancel(Player, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(bIsExiting)
		{
			ExitTimer += DeltaTime;
			DragonComp.RequestLocomotionDragonAndPlayer(n"TaillTeenPull");
			if(ExitTimer >= ExitDuration)
			{
				if(HasControl())
					CrumbStopInteracting();
			}
		}
		
		else
		{
			if(MoveComp.PrepareMove(Movement))
			{
				if(HasControl())
				{				
					if(WasActionStarted(ActionNames::Cancel))
					{
						CrumbReleasePulley();
					}

					FVector Input = MoveComp.MovementInput;
					
					float InputDotPulley = Input.DotProduct(PulleyInteraction.ActorForwardVector);

					float PullingSpeed;
					if(InputDotPulley < 0)
						PullingSpeed = PulleySettings.PullingBackSpeed;
					else
						PullingSpeed = PulleySettings.PullingForwardSpeed;

					float DeltaMoveSpeed = InputDotPulley * PullingSpeed * DeltaTime;
					PulleyInteraction.MovePulley(DeltaMoveSpeed);

					FVector TargetPos = PulleyInteraction.InteractComp.WorldLocation;
					Movement.AddDelta(TargetPos - Player.ActorLocation);
					Movement.SetRotation(PulleyInteraction.InteractComp.WorldRotation);
				}
				// Remote
				else
				{
					Movement.ApplyCrumbSyncedGroundMovement();
				}
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"TaillTeenPull");
		}
		DragonComp.DragonMesh.SetAnimVectorParam(n"GroundUp", PulleyInteraction.InteractComp.UpVector);
		DragonComp.DragonMesh.SetAnimFloatParam(n"PullbackThreshold", PulleyInteraction.PullAlpha);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbReleasePulley()
	{
		bIsExiting = true;
		PulleyInteraction.OnRelease();
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		if(PulleyInteraction.PullAlpha > PulleySettings.LongExitFractionThreshold)
		{
			ExitDuration = PulleySettings.LongExitDuration;
			DragonComp.DragonMesh.SetAnimBoolParam(n"PlayLongExit", true);
		}
		else
		{
			ExitDuration = PulleySettings.NormalExitDuration;
			DragonComp.DragonMesh.SetAnimBoolParam(n"PlayLongExit", false);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbStopInteracting()
	{
		LeaveInteraction();
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
}