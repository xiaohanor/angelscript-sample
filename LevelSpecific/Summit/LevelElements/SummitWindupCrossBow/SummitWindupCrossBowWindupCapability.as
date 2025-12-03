class USummitWindupCrossBowWindupCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitWindupCrossBow WindupCrossBow;

	UPlayerTailTeenDragonComponent DragonComp;
	UHazeMovementComponent MoveComp;
	UTeenDragonRollComponent RollComp;
	USteppingMovementData Movement;

	UTeenDragonRollSettings RollSettings;

	bool bHasBeenReleased = false;

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

		WindupCrossBow = Cast<ASummitWindupCrossBow>(Params.Interaction.Owner);
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Player.ApplyBlendToCurrentView(2);

		DragonComp.DragonMeshOffsetComponent.FreezeTransformAndLerpBackToParent(this, 0.5);
		Player.TeleportActor(WindupCrossBow.BasketRoot.WorldLocation, Params.Interaction.WorldRotation, this, false);
		RollComp = UTeenDragonRollComponent::Get(Player);

		FHazePointOfInterestFocusTargetInfo POI;
		POI.SetFocusToWorldLocation(WindupCrossBow.GetAimWorldLocation());
		FApplyPointOfInterestSettings POISettings;
		POISettings.Duration = 2.0;
		Player.ApplyPointOfInterest(this, POI, POISettings, POISettings.Duration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);	
		//Player.DeactivateCamera(WindupCrossBow.Camera, 0.0);

		DragonComp.AnimationState.Clear(this);

		if(WindupCrossBow != nullptr)
			WindupCrossBow.Restore();

		bHasBeenReleased = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasBeenReleased && WindupCrossBow.bHasBeenReleased)
		{
			ApplyRelease(DeltaTime);

			FHazePointOfInterestFocusTargetInfo POI;
			POI.SetFocusToWorldLocation(WindupCrossBow.GetAimWorldLocation());
			FApplyPointOfInterestSettings POISettings;
			POISettings.Duration = 0.5;
			Player.ApplyPointOfInterest(this, POI, POISettings, POISettings.Duration * 0.5);

			//Player.DeactivateCamera(WindupCrossBow.Camera, 1);
		}
		else if(bHasBeenReleased)
		{
			UpdateRelease(DeltaTime);

			if(!WindupCrossBow.bPlayerIsInActionArea[Player])
			{
				RollComp.RollUntilImpactInstigators.Add(this);
				LeaveInteraction();
			}
		}
		else
		{
			UpdateWindup(DeltaTime);
		}
	}

	void ApplyRelease(float DeltaTime)
	{
		bHasBeenReleased = true;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Mul = Math::Lerp(0.25, 1, WindupCrossBow.GetWindupAmount());
				FVector RequiredVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
					Player.ActorLocation, 
					WindupCrossBow.GetAimWorldLocation(), 
					MoveComp.GetGravityForce(), 
					WindupCrossBow.ReleaseSpeed * Mul);	

				Movement.AddVelocity(RequiredVelocity * Mul);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRoll, this, EInstigatePriority::Interaction);
			DragonComp.RequestLocomotionDragonAndPlayer(n"RollMovement");
		}
	}

	void UpdateRelease(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddOwnerVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRoll, this, EInstigatePriority::Interaction);
			DragonComp.RequestLocomotionDragonAndPlayer(n"RollMovement");
		}
	}

	void UpdateWindup(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float RollDirection = 0;
				if (!MoveComp.MovementInput.IsNearlyZero())
				{
					RollDirection = WindupCrossBow.ActorForwardVector.DotProduct(-MoveComp.MovementInput);
					if(RollDirection < 0)
						RollDirection = 0;
				}

				float WindupAlpha = Math::Min(WindupCrossBow.GetWindupAmount() / 1, 1);
				WindupAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(1, 0.25), WindupAlpha);
				float WindupSpeed = WindupAlpha * (1 / WindupCrossBow.WindupTime) * RollDirection;

				float WindupAmount = MoveComp.MovementInput.Size() * DeltaTime * WindupSpeed;

				WindupCrossBow.SyncedWindupAmount.SetValue(WindupAmount);
				FVector WindupDelta =  WindupCrossBow.AddWindupAmount(WindupAmount);
				
				float RollAnimationSpeed = RollSettings.RollStartSpeed * MoveComp.MovementInput.Size();
				if(WindupCrossBow.GetWindupAmount() >= 1 - SMALL_NUMBER)
					RollAnimationSpeed = 0;
				else
					RollAnimationSpeed *= WindupAlpha;
				
				Movement.AddDeltaWithCustomVelocity(WindupDelta, Player.ViewRotation.RightVector * RollAnimationSpeed * RollDirection);
			}
			// Remote
			else
			{
				float WindupAmount = WindupCrossBow.SyncedWindupAmount.GetValue();
				WindupCrossBow.AddWindupAmount(WindupAmount);
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			if (MoveComp.HorizontalVelocity.Size() > 1.0)
			{
				DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRoll, this, EInstigatePriority::Interaction);
				DragonComp.RequestLocomotionDragonAndPlayer(n"RollMovement");
			}
			else
			{
				DragonComp.AnimationState.Apply(ETeenDragonAnimationState::FloorMovement, this, EInstigatePriority::Interaction);
				DragonComp.RequestLocomotionDragonAndPlayer(n"RollMovement");
			}
		
		}
	}
};
