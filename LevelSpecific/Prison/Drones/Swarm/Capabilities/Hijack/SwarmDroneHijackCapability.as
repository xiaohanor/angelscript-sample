struct FSwarmDroneHijackCapabiltyActivationParams
{
	USwarmDroneHijackTargetableComponent HijackComponent = nullptr;
}

struct FSwarmDroneHijackCapabilityDeactivationParams
{
	bool bHackingStarted = false;
}

struct FSwarmDroneHijackBotInitialData
{
	float SwarmificationMultiplier;
}

struct FSwarmDroneHijackBotDiveData
{
	// Relative to targetable component
	FTransform RelativeBotTargetTransform;

	FVector LaunchVelocity;

	float FlyTime;
	bool bCloseToTarget = false;
}

class USwarmDroneHijackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackCapability);

	default DebugCategory = Drone::DebugCategory;

	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;
	UPlayerSwarmDroneHijackComponent PlayerSwarmDroneHijackComponent;
	USwarmDroneHijackTargetableComponent HijackComponent;
	UPlayerTargetablesComponent TargetablesComponent;
	UPlayerMovementComponent MovementComponent;

	TArray<FSwarmDroneHijackBotDiveData> BotsDiveData;
	TArray<FSwarmDroneHijackBotInitialData> BotsInitialData;

	float AccumulatedHijackDelay;

	int SwarmBotsHackingCount;
	bool bHackingStarted;

	const float SwarmificationDuration = 0.4;
	bool bSwarmifying;
	bool bDiving;

	bool bCancelPromptShown;

	FVector PreviousPlayerVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		PlayerSwarmDroneHijackComponent = UPlayerSwarmDroneHijackComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSwarmDroneHijackCapabiltyActivationParams& ActivationParams) const
	{
		if(PlayerSwarmDroneHijackComponent.ForcedHijackableTargetComponent != nullptr)
        {
            ActivationParams.HijackComponent = PlayerSwarmDroneHijackComponent.ForcedHijackableTargetComponent;
            return true;
        }

		if (!WasActionStarted(ActionNames::WeaponFire))
			return false;

		if (HijackComponent != nullptr)
			return false;

		USwarmDroneHijackTargetableComponent TargetedHijackComponent = Cast<USwarmDroneHijackTargetableComponent>(TargetablesComponent.GetPrimaryTargetForCategory(SwarmDroneTags::SwarmDroneHijackTargetableCategory));
		if (TargetedHijackComponent == nullptr)
			return false;

		ActivationParams.HijackComponent = TargetedHijackComponent;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmDroneHijackCapabilityDeactivationParams& DeactivationParams) const
	{
		// if (!PlayerSwarmDroneComponent.bSwarmModeActive)
		// 	return true;

		if (PlayerSwarmDroneHijackComponent.IsSwarmHijackCancelBlocked())
			return false;

		if (!bHackingStarted)
			return false;

		if (WasActionStarted(ActionNames::Cancel) || HijackComponent.IsDisabled())
		{
			DeactivationParams.bHackingStarted = bHackingStarted;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSwarmDroneHijackCapabiltyActivationParams ActivationParams)
	{
		HijackComponent = ActivationParams.HijackComponent;
		PlayerSwarmDroneHijackComponent.CurrentHijackTargetable = HijackComponent;

		// Consume and Block movement
		PreviousPlayerVelocity = MovementComponent.Velocity.ConstrainToPlane(Player.MovementWorldUp);
		MovementComponent.Reset(true);

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmAirMovementCapability, this);
		Player.BlockCapabilities(DroneCommonTags::BaseDroneMovement, this);

		MovementComponent.FollowComponentMovement(HijackComponent, this, EMovementFollowComponentType::Teleport, EInstigatePriority::High);

		SwarmBotsHackingCount = 0;
		AccumulatedHijackDelay = 0;
		bHackingStarted = false;
		bDiving = false;
		bSwarmifying = true;
		bCancelPromptShown = false;

		// Prepare bots
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = PlayerSwarmDroneComponent.SwarmBots[i];

			// No respawning during hijack
			SwarmBot.ApplyRespawnBlock(this);

			// Add tasty multiplier for use in swarmification
			FSwarmDroneHijackBotInitialData BotData;
			BotData.SwarmificationMultiplier = 1.0 - Math::Max(0, SwarmBot.ActorUpVector.DotProduct(Player.ActorUpVector));
			BotData.SwarmificationMultiplier = Math::RandRange(0.2, 2);
			BotsInitialData.Add(BotData);

			// Swarmification will be jump like; don't add more impulse if player is jumping.
			FVector Impulse = Player.MovementWorldUp * Math::RandRange(800, 1000);
			if (MovementComponent.IsInAir())
				Impulse *= 0.5;

			SwarmBot.SetActorVelocity(Impulse + PreviousPlayerVelocity);
		}

		if(PlayerSwarmDroneHijackComponent.ForcedHijackableTargetComponent != nullptr && HasControl())
		{
			Crumb_StartInstantHijack();
		}
		else
		{
			// Freeze camera if player is airborne
			if (MovementComponent.IsInAir())
				Player.CameraOffsetComponent.SnapToTransform(this, Player.CurrentlyUsedCamera.WorldTransform);

			FSwarmDroneHijackParams HijackParams;
			HijackParams.Player = Player;
			HijackComponent.StartPrepareDive(HijackParams);
		}

		PlayerSwarmDroneHijackComponent.bHijackActive = true;

		USwarmDroneEventHandler::Trigger_OnHackInitiated(Player);
		USwarmDroneEventHandler::Trigger_StopSwarmBotMovement(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FSwarmDroneHijackCapabilityDeactivationParams DeactivationParams)
	{
		// Clean bots of any hijacking shenanigans
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			PlayerSwarmDroneComponent.SwarmBots[i].ResetScale(); // Eman TODO: Gross! Juice up
			PlayerSwarmDroneComponent.SwarmBots[i].ClearRespawnBlock(this);
			// PlayerSwarmDroneComponent.SwarmBots[i].PointLight.SetVisibility(true);
		}

		Player.GetMeshOffsetComponent().ResetOffsetWithLerp(this, 0.2);

		MovementComponent.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::Release);
		
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(SwarmDroneTags::SwarmAirMovementCapability, this);
		Player.UnblockCapabilities(DroneCommonTags::BaseDroneMovement, this);

		if (DeactivationParams.bHackingStarted)
		{
			PlayerSwarmDroneHijackComponent.bHijackExit = true;

			// Wipe dat butt
			if (bCancelPromptShown)
			{
				Player.RemoveCancelPromptByInstigator(this);
				bCancelPromptShown = false;
			}

			HijackComponent.StopHijack();

			USwarmDroneHijackEventHandler::Trigger_OnHijackEnd(Player);
			USwarmDroneEventHandler::Trigger_OnHackStop(Player);
		}

		// Clear camera stuff with blend
		Player.ApplyBlendToCurrentView(1.0);
		Player.CameraOffsetComponent.ClearOffset(this);
		Player.ClearCameraSettingsByInstigator(this, 0.0);

		HijackComponent = nullptr;

		PlayerSwarmDroneHijackComponent.bHijackActive = false;
		BotsDiveData.Empty();
		BotsInitialData.Empty();

		URemoteHackingEventHandler::Trigger_OnHackingStopped(Player);

		PlayerSwarmDroneHijackComponent.ForcedHijackableTargetComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			return;

		if (IsActive())
			return;

		if (PlayerSwarmDroneHijackComponent.TargetableWidgetClass.IsValid())
			TargetablesComponent.ShowWidgetsForTargetables(USwarmDroneHijackTargetableComponent, PlayerSwarmDroneHijackComponent.TargetableWidgetClass);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Wait for swarmification before diving into panel
		if (bSwarmifying)
		{
			if (ActiveDuration < SwarmificationDuration)
			{
				TickSwarmification(DeltaTime);
				return;
			}

			if (HasControl())
				Crumb_StartDiveHijack();
		}

		// Tick dive and check when it's done
		if (bDiving && PlayerSwarmDroneHijackComponent.ForcedHijackableTargetComponent == nullptr)
		{
			TickSwarmDive(DeltaTime);

			if (SwarmBotsHackingCount == SwarmDrone::DeployedBotCount)
			{
				USwarmDroneHijackEventHandler::Trigger_OnHijackDiveEnd(Player);

				// Check if we are done with diving
				if (AccumulatedHijackDelay >= HijackComponent.HijackSettings.HijackDelayAfterDive)
				{
					bDiving = false;
					bHackingStarted = true;
				}

				AccumulatedHijackDelay += DeltaTime;
			}
		}

		if (bHackingStarted)
		{
			if (!bCancelPromptShown && !PlayerSwarmDroneHijackComponent.IsSwarmHijackCancelBlocked())
			{
				Player.ShowCancelPrompt(this);
				bCancelPromptShown = true;
			}
		}

		// Keep up bots with player
		FVector MoveDelta = MovementComponent.Velocity * DeltaTime + MovementComponent.GetFollowVelocity() * DeltaTime;
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = PlayerSwarmDroneComponent.SwarmBots[i];
			SwarmBot.SetActorLocation(SwarmBot.ActorLocation + MoveDelta);
		}
	}

	// Build up towards dive
	void TickSwarmification(float DeltaTime)
	{
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = PlayerSwarmDroneComponent.SwarmBots[i];

			// Tick swarmification jump
			FVector Velocity = SwarmBot.ActorVelocity - SwarmBot.MovementWorldUp * Drone::Gravity * 0.8 * DeltaTime;
			Velocity -= PreviousPlayerVelocity * DeltaTime * 3.0;
			SwarmBot.SetActorVelocity(Velocity);
			SwarmBot.AddActorWorldOffset(Velocity * DeltaTime);
		}

		// Eman TODO: Määähh.... talk to peeps about this...
		// Camera juice
		float Alpha = Math::Saturate(ActiveDuration / SwarmificationDuration);
		float Fov = 10 * Alpha;
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(Fov, this, 0.0);

		// Force feedback juice
		float TriggerRumble = Math::Lerp(PlayerSwarmDroneHijackComponent.SwarmificationTriggerRumbleRange.X, PlayerSwarmDroneHijackComponent.SwarmificationTriggerRumbleRange.Y, Alpha);
		Player.SetFrameForceFeedback(0, 0, 0, TriggerRumble);
	}

	// Do lil' jump towards panel
	void TickSwarmDive(float DeltaTime)
	{
		const float ActiveDiveDuration = ActiveDuration - SwarmificationDuration;

		// Jump towards hijack component mesh
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = PlayerSwarmDroneComponent.SwarmBots[i];
			FSwarmDroneHijackBotDiveData& BotData = BotsDiveData[i];

			float Alpha = Math::Saturate(ActiveDiveDuration / (BotsDiveData[i].FlyTime * 0.98));
			float Scale = Math::Lerp(SwarmBot.RetractedScale, 0.0, Alpha);
			SwarmBot.GroupSkelMeshAnimData.Transform.SetScale3D(FVector(Scale));

			// Add some chaos juice
			if (ActiveDiveDuration < (i % 4)* i * 0.003)
				continue;

			FVector TargetLocation = HijackComponent.WorldTransform.TransformPositionNoScale(BotData.RelativeBotTargetTransform.Location);
			FQuat TargetRotation = HijackComponent.WorldTransform.TransformRotation(BotData.RelativeBotTargetTransform.Rotation);

			if (BotData.bCloseToTarget)
			{
				// Just lerp to targetlocation; increase speed the longer the capbility has been active
				FVector BotLocation = Math::VInterpTo(SwarmBot.ActorLocation, TargetLocation, DeltaTime, 18 * ActiveDiveDuration);
				SwarmBot.SetActorLocation(BotLocation);
			}
			else
			{
				// Tick launch towards target
				FVector Velocity = SwarmBot.ActorVelocity - SwarmBot.MovementWorldUp * Drone::Gravity * DeltaTime;
				FVector NextLocation = SwarmBot.ActorLocation + Velocity * DeltaTime;

				// Eman TODO: Temp 0.9 hard limit for flying
				if (LocationIsNearOrPassedTarget(NextLocation, TargetLocation) || ActiveDiveDuration >= 0.9)
				{
					Velocity = FVector::ZeroVector;
					NextLocation = SwarmBot.ActorLocation;

					BotData.bCloseToTarget = true;
					SwarmBotsHackingCount++;
				}

				SwarmBot.SetActorVelocity(Velocity);
				SwarmBot.SetActorLocation(NextLocation);
			}

			FQuat Rotation = Math::QInterpTo(SwarmBot.ActorQuat, TargetRotation, DeltaTime, 3.0);
			SwarmBot.SetActorRotation(Rotation);
		}

		if (ActiveDiveDuration < BotsDiveData.Last().FlyTime * 0.2)
			Player.SetFrameForceFeedback(PlayerSwarmDroneHijackComponent.DiveRumble);
	}

	void PrepareDive()
	{
		// Create jump data for each little bugger
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			FSwarmDroneHijackBotDiveData BotData = CreateBotData(i);
			BotsDiveData.Add(BotData);
			PlayerSwarmDroneComponent.SwarmBots[i].SetActorVelocity(BotData.LaunchVelocity);
		}
	}

	FSwarmDroneHijackBotDiveData CreateBotData(int BotIndex)
	{
		// Get target dive transform
		FTransform WorldBotTransform = SwarmDroneHijack::GetRandomWorldDiveTransformForHijackable(HijackComponent);

		// Now calculate launch velocity
		FVector TargetWorldLocation = WorldBotTransform.Location;
		FVector Start = PlayerSwarmDroneComponent.SwarmBots[BotIndex].ActorLocation;

		float DistanceToTarget = Start.Distance(TargetWorldLocation);
		float LaunchSpeed = DistanceToTarget * 2.0; // Former clamp [320-800]
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Start, TargetWorldLocation, Drone::Gravity, LaunchSpeed + BotIndex * BotIndex + BotIndex);

		// Finally create and return struct
		FSwarmDroneHijackBotDiveData BotData;
		BotData.RelativeBotTargetTransform = WorldBotTransform * HijackComponent.WorldTransform.Inverse();
		BotData.LaunchVelocity = LaunchVelocity;
		BotData.FlyTime = DistanceToTarget / LaunchSpeed;

		return BotData;
	}

	bool LocationIsNearOrPassedTarget(FVector Location, FVector Target)
	{
		// Location is close to target
		if (Location.DistSquared(Target) <= (1000.0))
			return true;

		// Location has passed target
		FVector PlayerToTarget = (Target - Player.ActorLocation).GetSafeNormal();
		FVector LocationToTarget = (Target - Location).GetSafeNormal();
		if (PlayerToTarget.DotProduct(LocationToTarget) < 0)
			return true;

		return false;
	}

	UFUNCTION(CrumbFunction)
	void Crumb_StartInstantHijack()
	{
		bDiving = false;
		bHackingStarted = true;

		// Start hacking
		FSwarmDroneHijackParams HijackParams;
		HijackParams.Player = Player;
		HijackComponent.StartHijack(HijackParams);

		// Fire away!
		USwarmDroneHijackEventHandler::Trigger_OnHijackStart(Player);
	}

	UFUNCTION(CrumbFunction)
	void Crumb_StartDiveHijack()
	{
		bSwarmifying = false;
		PrepareDive();
		bDiving = true;

		// Clear swarmification settings
		Player.ClearCameraSettingsByInstigator(this, 1);

		// Snap player to position
		Player.TeleportActor(HijackComponent.GetWorldPlayerSnapLocation(), FRotator::ZeroRotator, this, false);

		// Trigger dive effect event
		FSwarmDroneHijackDiveParams DiveParams;
		DiveParams.DiveDuration = BotsDiveData.Last().FlyTime;
		DiveParams.BlendTime = DiveParams.DiveDuration * 0.4;
		USwarmDroneHijackEventHandler::Trigger_OnHijackDiveStart(Player, DiveParams);
		USwarmDroneEventHandler::Trigger_OnHackDive(Player, DiveParams);
		
		// Start hacking as soon as bots start diving
		FSwarmDroneHijackParams HijackParams;
		HijackParams.Player = Player;
		HijackComponent.StartHijack(HijackParams);

		USwarmDroneHijackEventHandler::Trigger_OnHijackStart(Player);
		USwarmDroneEventHandler::Trigger_OnHackStart(Player);
	}
}