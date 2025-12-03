class USummitCrossbowPullCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	ASummitCrossbow Crossbow;

	UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	USummitCrossbowSettings CrossbowSettings;

	float ExitTimer = 0.0;
	float ExitDuration = 0.0;
	bool bIsExiting = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		
		Crossbow = Cast<ASummitCrossbow>(Params.Interaction.Owner);
		Crossbow.StartPulling();
		CrossbowSettings = USummitCrossbowSettings::GetSettings(Crossbow);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		if (Crossbow.Camera != nullptr)
			Player.ActivateCamera(Crossbow.Camera, CrossbowSettings.CameraBlendInTime, this);

		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this);

		ExitTimer = 0.0;
		bIsExiting = false;

		Player.BlockCapabilities(n"InteractionCancel", this);

		Crossbow.PullInteraction.SetPlayerIsAbleToCancel(Player, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		
		if (Crossbow.Camera != nullptr)
			Player.DeactivateCamera(Crossbow.Camera, CrossbowSettings.CameraBlendOutTime);

		DragonComp.AnimationState.Clear(this);
		Player.SetActorVelocity(FVector::ZeroVector);

		Player.UnblockCapabilities(n"InteractionCancel", this);
		Crossbow.PullInteraction.SetPlayerIsAbleToCancel(Player, true);
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
				StopInteracting();
			}
		}
		else
		{
			if (MoveComp.PrepareMove(Movement))
			{
				if (HasControl())
				{
					if(WasActionStarted(ActionNames::Cancel))
					{
						CrumbReleaseCrossbow();
					}

					FVector Input = MoveComp.MovementInput;

					float InputDotBasket = Input.DotProduct(Crossbow.BasketRoot.ForwardVector);

					float MoveSpeed;
					if(InputDotBasket < 0)
						MoveSpeed = CrossbowSettings.BasketPullBackSpeed;
					else
						MoveSpeed = CrossbowSettings.BasketPullForwardSpeed;

					float DeltaMoveSpeed = InputDotBasket * MoveSpeed * DeltaTime;
					Crossbow.MovePullDelta(-DeltaMoveSpeed);

					FVector TargetPos = Crossbow.PullInteraction.WorldLocation;
					Movement.AddDelta(TargetPos - Player.ActorLocation);
					Movement.SetRotation(Crossbow.PullInteraction.WorldRotation);
				}
				// Remote
				else
				{
					Movement.ApplyCrumbSyncedGroundMovement();
				}

				MoveComp.ApplyMove(Movement);
				DragonComp.RequestLocomotionDragonAndPlayer(n"TaillTeenPull");
			}
		}
		Player.SetAnimVectorParam(n"GroundUp", Crossbow.PullInteraction.UpVector);
		Player.SetAnimFloatParam(n"PullbackThreshold", Crossbow.GetPullAlpha());
	}
	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbReleaseCrossbow()
	{
		bIsExiting = true;
		Crossbow.StopPulling();
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		if(Crossbow.GetPullAlpha() > CrossbowSettings.LongExitFractionThreshold)
		{
			ExitDuration = CrossbowSettings.LongExitDuration;
			DragonComp.DragonMesh.SetAnimBoolParam(n"PlayLongExit", true);
		}
		else
		{
			ExitDuration = CrossbowSettings.NormalExitDuration;
			DragonComp.DragonMesh.SetAnimBoolParam(n"PlayLongExit", false);
		}
	}

	void StopInteracting()
	{
		LeaveInteraction();
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
};