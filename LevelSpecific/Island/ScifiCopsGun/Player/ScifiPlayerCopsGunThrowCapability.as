

class UScifiPlayerCopsGunThrowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunThrow");
	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 95;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UScifiPlayerCopsGunManagerComponent Manager;
	UHazeMovementComponent Movement;
	UPlayerAimingComponent AimingComp;
	UScifiCopsGunInternalEnvironmentThrowTargetableComponent EnvironmentTarget;

	UScifiPlayerCopsGunSettings Settings;
	UScifiCopsGunCrosshair CrosshairWidget;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;
	TArray<bool> InternalWeaponsAreBack;
	default InternalWeaponsAreBack.SetNum(EScifiPlayerCopsGunType::MAX);

	float TimeLeftToDeativate = 0;
	bool bShouldDeactivate = false;
	bool bTriggerThrowOnDeactivation = false;


	float NextInvironmentTargetUpdate = 0;
	int LastReplicatedFrame = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		Movement = UHazeMovementComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		Settings = Manager.Settings;
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		InternalWeaponsAreBack[EScifiPlayerCopsGunType::Left] = true;
		InternalWeaponsAreBack[EScifiPlayerCopsGunType::Right] = true;
		EnvironmentTarget = Manager.InternalEnvironmentTarget;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsActioning(ActionNames::WeaponAim))
			return false;

		if(!Manager.WeaponsAreAttachedToPlayer())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FScifiPlayerCopsGunWeaponTarget& DeactivationParams) const
	{
		if(!bShouldDeactivate)
			return false;

		if(TimeLeftToDeativate > 0)
			return false;
		
		// Should we actually trigger the throw
		// on the weapons or should we just end the throw capability
		if(bTriggerThrowOnDeactivation)
		{
			DeactivationParams.bThrowWeapon = true;
			DeactivationParams.bHasOverheat = Manager.HasTriggeredOverheat();

			// No target, so we throw it into the world
			if(Manager.CurrentThrowTargetPoint == nullptr)
			{
				FVector Forward = Player.GetViewRotation().ForwardVector;
				if(Movement.IsOnAnyGround() && Forward.DotProduct(Movement.WorldUp) < KINDA_SMALL_NUMBER)
				{
					Forward = Forward.VectorPlaneProject(Movement.WorldUp).GetSafeNormal();
				}
	
				DeactivationParams.WorldLocation = Player.GetActorCenterLocation() + (Forward * Settings.WeaponThrowDistance);		
			}
			else
			{
				DeactivationParams.Target = Manager.CurrentThrowTargetPoint;
				if(DeactivationParams.Target != nullptr)
				{
					DeactivationParams.RelativeLocation = Manager.CurrentThrowTargetPoint.RelativeLocation;
					DeactivationParams.RelativeRotation = Manager.CurrentThrowTargetPoint.RelativeRotation;
					DeactivationParams.TargetAttachment = DeactivationParams.Target.GetAttachParent();
				}
			}

			DeactivationParams.ReplicatedFrame = LastReplicatedFrame + 1;
		}
		else
		{
			Manager.AttachWeaponToPlayerThigh(LeftWeapon, this);
			Manager.AttachWeaponToPlayerThigh(RightWeapon, this);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.bPlayerWantsToThrowWeapon = true;
		Manager.TimeLeftUntilReturn = -1;
		Manager.BulletsLeftToReturn = -1;
	
		Player.BlockCapabilities(n"MovementFacing", this);

		// Pickup the weapons
		Manager.AttachWeaponToPlayerHand(LeftWeapon, this);
		Manager.AttachWeaponToPlayerHand(RightWeapon, this);
		
		if(Settings.ThrowInputType != EScifiPlayerCopsGunThrowType::ThrowOnAimPress)
		{
			AimingComp.StartAiming(this, Manager.AimSettings);
			CrosshairWidget = Cast<UScifiCopsGunCrosshair>(AimingComp.GetCrosshairWidget(this));
			CrosshairWidget.bAiming = true;

			Player.EnableStrafe(this);
			float RotationSpeedMultiplier = Math::Clamp(Player.ActorForwardVector.AngularDistanceForNormals(Player.ViewRotation.ForwardVector) / PI, 0.0, 1.0);
			UPlayerStrafeSettings::SetFacingDirectionInterpSpeed(Player, 2000.0 * RotationSpeedMultiplier, this);	

			Player.ApplyCameraSettings(Manager.AimCameraSettings, 2, this);
			Manager.AimDownSightInstigators.Add(this);
		}

		UScifiCopsGunEventHandler::Trigger_OnAimStarted(LeftWeapon);
		UScifiCopsGunEventHandler::Trigger_OnAimStarted(RightWeapon);
		UScifiPlayerCopsGunEventHandler::Trigger_OnAimStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FScifiPlayerCopsGunWeaponTarget DeactivationParams)
	{	
		LastReplicatedFrame = DeactivationParams.ReplicatedFrame;

		if(DeactivationParams.bThrowWeapon)
		{
			// Make sure the throw at target is in the same location
			if(DeactivationParams.Target == EnvironmentTarget)
			{
				if(EnvironmentTarget.AttachParent != DeactivationParams.TargetAttachment)
					EnvironmentTarget.AttachTo(DeactivationParams.TargetAttachment);

				EnvironmentTarget.SetRelativeLocationAndRotation(DeactivationParams.RelativeLocation, DeactivationParams.RelativeRotation);
			}

			if(!DeactivationParams.bHasOverheat)
			{
				Manager.ClearHeat();
			}

			Manager.ThrowWeapons(DeactivationParams, this);
		}

		Manager.bPlayerWantsToThrowWeapon = false;
		bShouldDeactivate = false;
		bTriggerThrowOnDeactivation = false;
		TimeLeftToDeativate = 0;
		//bHasInitializedThrow = false;

		//Player.UnblockCapabilities(n"CopsGunShootInput", this);
		Player.UnblockCapabilities(n"MovementFacing", this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::WeaponAim);

		if(Settings.ThrowInputType != EScifiPlayerCopsGunThrowType::ThrowOnAimPress)
		{
			AimingComp.StopAiming(this);
			CrosshairWidget.bAiming = false;
			CrosshairWidget = nullptr;

			Player.DisableStrafe(this);
			Player.ClearStrafeSpeedScale(this);
			UPlayerStrafeSettings::ClearFacingDirectionInterpSpeed(Player, this);

			Manager.AimDownSightInstigators.RemoveSingleSwap(this);
			Player.ClearCameraSettingsByInstigator(this);
		}

		UScifiCopsGunEventHandler::Trigger_OnAimStopped(LeftWeapon);
		UScifiCopsGunEventHandler::Trigger_OnAimStopped(RightWeapon);
		UScifiPlayerCopsGunEventHandler::Trigger_OnAimStopped(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Update the release button
		if(HasControl())
		{	
			// we have already deactivate this capability
			// just tick down the delay
			if(bShouldDeactivate)
			{
				TimeLeftToDeativate -= DeltaTime;
			}
			else
			{
				// We throw on release
				if(ShouldStartThrow())
				{
					bShouldDeactivate = true;
					TimeLeftToDeativate = Settings.ThrowAnimationTime + DeltaTime;
					bTriggerThrowOnDeactivation = true;
				}
				else if(!IsActioning(ActionNames::WeaponAim))
				{
					bShouldDeactivate = true;
				}

				if(Time::GameTimeSeconds > NextInvironmentTargetUpdate)
				{
					NextInvironmentTargetUpdate = Time::GameTimeSeconds + 0.2;
					LastReplicatedFrame++;
					NetUpdateEnvironmentTargetUnreliable(LastReplicatedFrame, EnvironmentTarget.bIsAutoAimEnabled, EnvironmentTarget.GetAttachParent(),
						EnvironmentTarget.RelativeLocation, EnvironmentTarget.RelativeRotation);
				}
			}
		}

		if(CrosshairWidget != nullptr)
			CrosshairWidget.bHasAimTarget = Manager.CurrentThrowTargetPoint != nullptr;

		if(Player.Mesh.CanRequestOverrideFeature())
		{
			Player.Mesh.RequestOverrideFeature(n"CopsGunThrow", this);
		}
	}

	bool ShouldStartThrow() const
	{
		if(Settings.ThrowInputType == EScifiPlayerCopsGunThrowType::ThrowOnAimPress)
			return true;

		if(Settings.ThrowInputType == EScifiPlayerCopsGunThrowType::ThrowAfterAimRelease)
			return !IsActioning(ActionNames::WeaponAim);

		if(Settings.ThrowInputType == EScifiPlayerCopsGunThrowType::ThrowOnAimHoldShootPress)
			return IsActioning(ActionNames::WeaponAim) && IsActioning(ActionNames::WeaponFire);

		return false;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetUpdateEnvironmentTargetUnreliable(
		int LastReceivedFrame,
		bool bIsAutoAimEnabled, 
		USceneComponent Attachement, 
		FVector RelativeLocation, 
		FRotator RelativeRotation)
	{
		if(HasControl())
			return;

		if(LastReplicatedFrame > LastReceivedFrame)
			return;

		LastReplicatedFrame = LastReceivedFrame;
		EnvironmentTarget.bIsAutoAimEnabled = bIsAutoAimEnabled;
		if(EnvironmentTarget.AttachParent != Attachement)
			EnvironmentTarget.AttachTo(Attachement);

		EnvironmentTarget.SetRelativeLocationAndRotation(RelativeLocation, RelativeRotation);
	}	
};