UCLASS(Abstract)
class ATundraSideInteractSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxRotateComp;
	default FauxRotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::TwoWaySynced;
	default FauxRotateComp.LocalRotationAxis = FVector(0.0, 1.0, 0.0);
	default FauxRotateComp.Friction = 1.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent LaunchInverseDeathTrigger;
	default LaunchInverseDeathTrigger.bAlwaysShowShapeInEditor = false;
	default LaunchInverseDeathTrigger.ShapeColor = FLinearColor::Red;
	default LaunchInverseDeathTrigger.EditorLineThickness = 3.0;
	default LaunchInverseDeathTrigger.Shape = FHazeShapeSettings::MakeBox(FVector(2000.0, 500.0, 2000.0));
	default LaunchInverseDeathTrigger.RelativeLocation = FVector(600.0, 0.0, 200.0);

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UStaticMeshComponent SwingPlank;

	UPROPERTY(EditAnywhere)
	FHazeFrameForceFeedback SwingFrameForceFeedback;

	UPROPERTY(DefaultComponent, Attach = SwingPlank)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerComp;
	default MoveIntoPlayerComp.RelativeRotation = FRotator(0.0, -180.0, 0.0);
	default MoveIntoPlayerComp.Shape = FHazeShapeSettings::MakeBox(FVector(43.034898, 127.473093, 2.549718));
	default MoveIntoPlayerComp.bImpartVelocityOnPushedPlayer = false;

	UPROPERTY(DefaultComponent, Attach = SwingPlank)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteractTargetable;
	default PunchInteractTargetable.bDisallowIfBehindLine = true;

	UPROPERTY(DefaultComponent, Attach = SwingPlank)
	UInteractionComponent MioInteractionComp;
	default MioInteractionComp.RelativeLocation = FVector(20.0, -40.0, 0);
	default MioInteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent, Attach = SwingPlank)
	UInteractionComponent ZoeInteractionComp;
	default ZoeInteractionComp.RelativeLocation = FVector(20.0, 40.0, 0);
	default ZoeInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UFauxPhysicsWeightComponent FauxWeightComp;
	default FauxWeightComp.MassScale = 0.15;
	default FauxWeightComp.bApplyInertia = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	UHazeCameraSettingsDataAsset SwingCamSettings;

	UPROPERTY(EditAnywhere)
	float PunchForce = 600.0;

	UPROPERTY(EditAnywhere)
	float PlayerLaunchImpulseMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float PlayerJumpOffImpulseMultiplier = 0.2;

	UPROPERTY(EditAnywhere)
	float BounceBackFromHittingPlayer = 0.3;

	UPROPERTY(EditAnywhere)
	float MaxPlayerHitLaunchImpulse = 1000.0;

	UPROPERTY(EditAnywhere)
	float MaxPlayerThrownOffImpulse = 1000.0;

	UPROPERTY(EditAnywhere)
	float MaxPlayerHitVerticalImpulseMultiplier = 0.3;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bCanPush", EditConditionHides))
	float MaxPushForce = 320.0;

	UPROPERTY(EditAnywhere)
	FVector PlayerCancelRelativeImpulse = FVector(500.0, 0.0, 200.0);

	/* This force feedback will play when the player cancels or jumps off */
	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect CancelForceFeedback;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect PunchForceFeedback;

	TArray<AHazePlayerCharacter> SwingingPlayers;
	TArray<AHazePlayerCharacter> PlayersToKill;
	TPerPlayer<uint> FrameOfAddingPlayerToKill;

	const float LaunchThreshold = -40.0;
	const float LaunchVelocityThreshold = -1.0;

	float TimeOfLaunch = -100.0;

	UFUNCTION()
	bool AreBothPlayersSwinging() const
	{
		return SwingingPlayers.Num() == 2;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FBox Box = UCableComponent::Get(this).GetBoundingBoxRelativeToOwner();
		FauxRotateComp.RelativeLocation = FVector::UpVector * (Box.Extent.Z * 2.0 * ActorScale3D.Z);
		SwingPlank.RelativeLocation = -FauxRotateComp.RelativeLocation;
		FauxWeightComp.RelativeLocation = -FauxRotateComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioInteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		MioInteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractStopped");
		ZoeInteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		ZoeInteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractStopped");

		PunchInteractTargetable.OnPunch.AddUFunction(this, n"OnPunch");
		MoveIntoPlayerComp.OnImpactPlayer.AddUFunction(this, n"OnSwingImpactPlayer");
	}

	UFUNCTION()
	private void OnSwingImpactPlayer(AHazePlayerCharacter Player)
	{
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if(!MoveComp.HasGroundContact())
			return;

		if(MoveComp.GroundContact.Actor == this)
			return;

		float Speed = GetSwingTranslationSpeed();
		FauxRotateComp.Velocity = -FauxRotateComp.Velocity * BounceBackFromHittingPlayer;
		// Since angular speed is in radians, TWO_PI is a full circle and TWO_PI * R would be the circumference of 
		Speed = Math::Min(Math::Abs(Speed), MaxPlayerHitLaunchImpulse) * Math::Sign(Speed);
		FVector Impulse = ActorForwardVector * Speed + FVector::UpVector * (Math::Abs(Speed) * MaxPlayerHitVerticalImpulseMultiplier);
		Player.AddMovementImpulse(Impulse);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for(int i = PlayersToKill.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = PlayersToKill[i];
			if(!Player.HasControl())
				continue;
			
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			if(MoveComp.HasGroundContact())
			{
				if(Time::FrameNumber != FrameOfAddingPlayerToKill[Player] || MoveComp.GroundContact.Actor != this)
				{
					PlayersToKill.RemoveAt(i);
					continue;
				}
			}

			if(!LaunchInverseDeathTrigger.IsPlayerInTrigger(Player))
			{
				Player.KillPlayer();
				PlayersToKill.RemoveAt(i);
				if(PlayersToKill.Num() == 0)
					LaunchInverseDeathTrigger.DisableTrigger(this);
			}
		}

		if(SwingingPlayers.Num() == 0)
			return;

		if(Math::RadiansToDegrees(FauxRotateComp.CurrentRotation) > LaunchThreshold)
			return;

		if(SwingVelocity > LaunchVelocityThreshold)
			return;

		for(AHazePlayerCharacter Player : SwingingPlayers)
		{
			LaunchPlayer(Player);
		}
	}

	float GetSwingTranslationSpeed()
	{
		// Since angular speed is in radians, TWO_PI is a full circle and TWO_PI * R would be the circumference of 
		float AngularSpeed = -FauxRotateComp.Velocity;
		float Speed = Math::Abs(FauxRotateComp.RelativeLocation.Z) * AngularSpeed;
		return Speed;
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		PlayersToKill.Add(Player);
		FrameOfAddingPlayerToKill[Player] = Time::FrameNumber;
		LaunchInverseDeathTrigger.EnableTrigger(this);
		UPlayerInteractionsComponent::Get(Player).KickPlayerOutOfAnyInteraction();
		UPlayerMovementComponent::Get(Player).AddPendingImpulse(SwingPlank.ForwardVector * (GetSwingTranslationSpeed() * PlayerLaunchImpulseMultiplier));
		TimeOfLaunch = Time::GetGameTimeSeconds();
		UTundraSideInteractSwingEffectHandler::Trigger_OnSwingingPlayerLaunched(this, FTundraSideInteractSwingLaunchEffectParams(Player));
	}

	UFUNCTION()
	private void OnInteractStarted(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);
		Player.AttachToComponent(InteractionComponent);
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		MoveComp.FollowComponentMovement(SwingPlank, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.ApplyCameraSettings(SwingCamSettings, 2, this);

		SwingingPlayers.Add(Player);
		UTundraSideInteractSwingSwingerComponent::GetOrCreate(Player).ActiveSwing = this;
		UTundraSideInteractSwingEffectHandler::Trigger_OnPlayerEnterSwing(this, FTundraSideInteractSwingInteractEffectParams(Player));
	}

	UFUNCTION()
	private void OnInteractStopped(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		Player.DetachFromActor();
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		MoveComp.UnFollowComponentMovement(this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		SwingingPlayers.Remove(Player);
		UTundraSideInteractSwingSwingerComponent::GetOrCreate(Player).ActiveSwing = nullptr;
		UTundraSideInteractSwingEffectHandler::Trigger_OnPlayerExitSwing(this, FTundraSideInteractSwingInteractEffectParams(Player));
		Player.ClearCameraSettingsByInstigator(this, 2);

		if(!PlayersToKill.Contains(Player))
			LaunchPlayer(Player);
	}

	UFUNCTION()
	private void OnPushInteractStarted(UInteractionComponent InteractionComponent,
	                                   AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);
		UTundraSideInteractSwingPusherPlayerComponent::GetOrCreate(Player).ActiveSwing = this;
	}

	UFUNCTION()
	private void OnPushInteractStopped(UInteractionComponent InteractionComponent,
	                                   AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		UTundraSideInteractSwingPusherPlayerComponent::GetOrCreate(Player).ActiveSwing = nullptr;
	}

	void OnPlayerPush(AHazePlayerCharacter PushingPlayer, float ForceMultiplier)
	{
		FauxRotateComp.ApplyImpulse(SwingPlank.WorldLocation, SwingPlank.ForwardVector * (MaxPushForce * ForceMultiplier));
	}

	UFUNCTION()
	private void OnPunch(FVector PlayerLocation)
	{
		FauxRotateComp.ApplyImpulse(SwingPlank.WorldLocation, SwingPlank.ForwardVector * PunchForce);

		AHazePlayerCharacter SwingingPlayer = SwingingPlayers.Num() > 0 ? SwingingPlayers[0] : nullptr;
		if(SwingingPlayer != nullptr)
		{
			SwingingPlayer.SetAnimTrigger(n"Punched");
			SwingingPlayer.PlayForceFeedback(PunchForceFeedback, false, true, this);
			Online::UnlockAchievement(n"PunchedOnSwing");
		}

		UTundraSideInteractSwingEffectHandler::Trigger_OnSnowMonkeyPunchSwing(this, FTundraSideInteractSwingPushEffectParams(Game::Mio, SwingingPlayer));	
	}

	UFUNCTION(BlueprintPure)
	float GetSwingVelocity() const property
	{
		return FauxRotateComp.Velocity;
	}

	FBox GetSwingBounds(FTransform&out OutTransform)
	{
		OutTransform = SwingPlank.WorldTransform;
		TArray<UStaticMeshComponent> CollisionMeshes;
		CollisionMeshes.Add(SwingPlank);
		SwingPlank.GetChildrenComponentsByClass(UStaticMeshComponent, false, CollisionMeshes);
		FBox Bounds;

		for(UStaticMeshComponent Mesh : CollisionMeshes)
		{
			Bounds += Mesh.GetBoundingBoxRelativeToTransform(OutTransform);
		}

		return Bounds;
	}

	float GetWorldDistanceToSwing(FVector Location)
	{
		FTransform Transform;
		FBox Bounds = GetSwingBounds(Transform);
		FHazeShapeSettings Shape = FHazeShapeSettings::MakeBox(Bounds.Extent);
		return Shape.GetWorldDistanceToShape(Transform, Location);
	}
}