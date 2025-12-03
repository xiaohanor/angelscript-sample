class UInnerCityWaterCannonCapability : UInteractionCapability
{
	AInnerCityWaterCannon WaterCannon;

	UPlayerAimingComponent AimComp;

	UHazeCapabilitySheet CapabilitySheet;
	
	default TickGroup = EHazeTickGroup::Movement;

	float GameTimeStartedShooting = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AimComp = UPlayerAimingComponent::Get(Player);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		WaterCannon = Cast<AInnerCityWaterCannon>(ActiveInteraction.Owner);
		WaterCannon.SetActorControlSide(Player);

		Player.StartCapabilitySheet(CapabilitySheet, this);

		Player.AttachToComponent(WaterCannon.InteractComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		Player.ActivateCamera(WaterCannon.CameraActor, 2.0, this, EHazeCameraPriority::VeryHigh);

		
		//Player.ShowCancelPrompt(this);

		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = false;
		AimComp.StartAiming(this, AimingSettings);

		Player.AddLocomotionFeature(WaterCannon.LocomotionFeature, this);

		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveLocomotionFeature(WaterCannon.LocomotionFeature, this);
		AimComp.StopAiming(this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		Player.DeactivateCamera(WaterCannon.CameraActor);

		
		//Player.RemoveCancelPromptByInstigator(this);

		WaterCannon.YawForceComp.Force = FVector::ZeroVector;
		WaterCannon.PitchForceComp.Force = FVector::ZeroVector;

		if (WaterCannon.bIsShootingWater)
		{
			WaterCannon.StopShooting();
			WaterCannon.IsNotShootingWater();
		}

	

		
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"WaterCannon", this);

		if(!WaterCannon.bIsInteracting)
		{
			WaterCannon.YawForceComp.Force = FVector(0.0,0.0,0.0);
			WaterCannon.PitchForceComp.Force = FVector(0.0,0.0,0.0);

				if(WaterCannon.bIsShootingWater)
					WaterCannon.StopShooting();
			return;
		}

		if (HasControl())
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			FVector2D CamInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

			MoveInput.X = Math::Clamp(MoveInput.X + CamInput.X, -1.0, 1.0);
			MoveInput.Y = Math::Clamp(MoveInput.Y + CamInput.Y, -1.0, 1.0);							
			
			WaterCannon.YawForceComp.Force = FVector::ForwardVector * MoveInput.X * WaterCannon.YawForce;
			WaterCannon.PitchForceComp.Force = FVector::ForwardVector * MoveInput.Y * WaterCannon.PitchForce;

			

			if(!Math::IsNearlyEqual(MoveInput.X, 0.0, ErrorTolerance = SMALL_NUMBER))
			{
				WaterCannon.HasStartedMovingYaw();
				WaterCannon.bHasStoppedMovingYaw = false;
			}else if(Math::IsNearlyEqual(MoveInput.X, 0.0, ErrorTolerance = SMALL_NUMBER) && !WaterCannon.bHasStoppedMovingYaw)
			{
				WaterCannon.HasStoppedMovingYaw();
				WaterCannon.bIsMovingYaw = true;
			}

			if(!Math::IsNearlyEqual(MoveInput.Y, 0.0, ErrorTolerance = SMALL_NUMBER))
			{
				WaterCannon.HasStartedMovingPitch();
				WaterCannon.bHasStoppedMovingPitch = false;
			}else if(Math::IsNearlyEqual(MoveInput.Y, 0.0, ErrorTolerance = SMALL_NUMBER) && !WaterCannon.bHasStoppedMovingPitch)
			{
				WaterCannon.bIsMovingPitch = true;
				WaterCannon.HasStoppedMovingPitch();
			}
					

			

			if (!WaterCannon.bIsShootingWater)
			{
				if (IsActioning(ActionNames::WeaponFire))
				{
					CrumbSetShooting(true);
				}
			}
			else
			{
				if (!IsActioning(ActionNames::WeaponFire) && Time::GetGameTimeSince(GameTimeStartedShooting) > 0.2)
				{
					CrumbSetShooting(false);
				}
			}

			
		}
		

	
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetShooting(bool bIsShooting)
	{
		if (bIsShooting)
		{
			GameTimeStartedShooting = Time::GameTimeSeconds;
			WaterCannon.Shoot();
			WaterCannon.IsShootingWater();
		}
		else
		{
			WaterCannon.StopShooting();
			WaterCannon.IsNotShootingWater();
		}
	}
};