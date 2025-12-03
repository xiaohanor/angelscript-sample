class ASummitWaterTempleInnerBlockInputDeathCurrentVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazePlaySlotAnimationParams ZoeWaterAnim;

	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazePlaySlotAnimationParams MioWaterAnim;

	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazePlaySlotAnimationParams AcidDragonWaterAnim;

	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazePlaySlotAnimationParams TailDragonWaterAnim;

	UPROPERTY(EditAnywhere, Category = "POI")
	FApplyPointOfInterestSettings POIApplySettings;
	default POIApplySettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Fast;
	default POIApplySettings.TurnDirection = ECameraPointOfInterestTurnType::ShortestPath;
	default POIApplySettings.bBlockFindAtOtherPlayer = true;

	UPROPERTY(EditAnywhere, Category = "POI")
	float POIBlendInTime = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> InCurrentShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect InCurrentRumble;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	TPerPlayer<UPlayerSwimmingComponent> SwimComp;
	TPerPlayer<UPlayerMovementComponent> MoveComp;
	TPerPlayer<UPlayerBabyDragonComponent> DragonComp;
	TArray<AHazePlayerCharacter> PlayersInVolume;
	TPerPlayer<bool> HasBlockedInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredVolume");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeftVolume");

		for(auto Player : Game::Players)
		{
			SwimComp[Player] = UPlayerSwimmingComponent::Get(Player);
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
			auto RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
			if(Player.IsMio())
				UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnMioDied");
			else
				UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnZoeDied");
		}
	}

	UFUNCTION()
	private void OnZoeDied()
	{
		OnPlayerDied(Game::Zoe);
	}

	UFUNCTION()
	private void OnMioDied()
	{
		OnPlayerDied(Game::Mio);
	}

	void OnPlayerDied(AHazePlayerCharacter Player)
	{
		ToggleFeedbackEffects(Player, false);
	}

	UFUNCTION()
	private void OnPlayerEnteredVolume(AHazePlayerCharacter Player)
	{
		PlayersInVolume.AddUnique(Player);
	}

	UFUNCTION()
	private void OnPlayerLeftVolume(AHazePlayerCharacter Player)
	{
		PlayersInVolume.RemoveSingleSwap(Player);
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if(!HasBlockedInput[RespawnedPlayer])
			return;

		UnblockCapabilities(RespawnedPlayer);
		ToggleAnimation(RespawnedPlayer, false);
		TogglePOI(RespawnedPlayer, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PlayersInVolume.IsEmpty())
			return;

		for(auto Player : PlayersInVolume)
		{
			if(DragonComp[Player] == nullptr)
				DragonComp[Player] = UPlayerBabyDragonComponent::Get(Player);

			if(HasBlockedInput[Player])
			{
				FQuat TargetRot = FQuat::MakeFromYZ(-ActorForwardVector, FVector::UpVector);
				Player.MeshOffsetComponent.WorldRotation = Math::RInterpTo(Player.MeshOffsetComponent.WorldRotation, TargetRot.Rotator(), DeltaSeconds, 2);
				if(MoveComp[Player].IsOnWalkableGround())
				{
					UnblockCapabilities(Player);
					ToggleAnimation(Player, false);
					TogglePOI(Player, false);
					ToggleFeedbackEffects(Player, false);
				}
				if(!SwimComp[Player].IsSwimming())
				{
					ToggleFeedbackEffects(Player, false);
				}
				continue;
			}

			if(SwimComp[Player].IsSwimming())
			{
				BlockCapabilities(Player);
				ToggleAnimation(Player, true);
				TogglePOI(Player, true);
				ToggleFeedbackEffects(Player, true);
			}
		}
	}

	private void BlockCapabilities(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingJump, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
		
		HasBlockedInput[Player] = true;
	}

	private void UnblockCapabilities(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingJump, this);
		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingDash, this);

		Player.MeshOffsetComponent.FreezeRotationAndLerpBackToParent(this, 0, EInstigatePriority::High);
		HasBlockedInput[Player] = false;
	}

	void ToggleAnimation(AHazePlayerCharacter Player, bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(Player.IsMio())
			{
				Player.PlaySlotAnimation(MioWaterAnim);
				DragonComp[Player].BabyDragon.Mesh.PlaySlotAnimation(AcidDragonWaterAnim);
			}
			else
			{
				Player.PlaySlotAnimation(ZoeWaterAnim);
				DragonComp[Player].BabyDragon.Mesh.PlaySlotAnimation(TailDragonWaterAnim);
			}
		}
		else
		{
			if(Player.IsMio())
			{
				if(Player.IsPlayingAnimAsSlotAnimation(MioWaterAnim.Animation))
					Player.StopSlotAnimation();
				
				if(DragonComp[Player].BabyDragon.Mesh.IsPlayingAnimAsSlotAnimation(AcidDragonWaterAnim.Animation))
					DragonComp[Player].BabyDragon.Mesh.StopAllSlotAnimations();
			}
			else
			{
				if(Player.IsPlayingAnimAsSlotAnimation(ZoeWaterAnim.Animation))
					Player.StopSlotAnimation();
				
				if(DragonComp[Player].BabyDragon.Mesh.IsPlayingAnimAsSlotAnimation(TailDragonWaterAnim.Animation))
					DragonComp[Player].BabyDragon.Mesh.StopAllSlotAnimations();
			}
		}
	}

	void TogglePOI(AHazePlayerCharacter Player, bool bToggleOn)
	{
		if(bToggleOn)
		{
			FHazePointOfInterestFocusTargetInfo FocusTargetInfo;
			FocusTargetInfo.SetFocusToActor(Player);
			FocusTargetInfo.SetWorldOffset(ActorForwardVector * 100);
			Player.ApplyPointOfInterest(this, FocusTargetInfo, POIApplySettings, POIBlendInTime, EHazeCameraPriority::High);
		}
		else
		{
			Player.ClearPointOfInterestByInstigator(this);
		}
	}

	void ToggleFeedbackEffects(AHazePlayerCharacter Player, bool bToggleOn)
	{
		if(bToggleOn)
		{
			Player.PlayForceFeedback(InCurrentRumble, true, true, this);
			Player.PlayCameraShake(InCurrentShake, this);
		}
		else
		{
			Player.StopForceFeedback(this);
			Player.StopCameraShakeByInstigator(this);
		}
	}
};