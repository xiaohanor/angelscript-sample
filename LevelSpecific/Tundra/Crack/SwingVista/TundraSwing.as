struct FSwingPerPlayerData
{
	UInteractionComponent InteractionComponent;
	UTundraPlayerSwingComponent SwingComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftComp;
	float StartBlendTime = -1;
	float LastFallDistance = 0;

	bool IsSitting() const
	{
		return InteractionComponent != nullptr;
	}
};

UCLASS(Abstract)
class ATundraSwing : AHazeActor
{
	default ActorTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UFauxPhysicsAxisRotateComponent FauxAxisRotator;
	default FauxAxisRotator.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;
	default FauxAxisRotator.ImpactMinStrength = 0;

	UPROPERTY(DefaultComponent, Attach=FauxAxisRotator)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach=Collision)
	UFauxPhysicsWeightComponent FauxWeight;

	UPROPERTY(DefaultComponent, Attach = FauxAxisRotator)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactComponent;
	
	UPROPERTY(DefaultComponent, Attach = FauxAxisRotator)
	UTundraShapeshiftingInteractionComponent  LeftInteraction;

	UPROPERTY(DefaultComponent, Attach = FauxAxisRotator)
	UTundraShapeshiftingInteractionComponent  RightInteraction;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent SwingCamera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent VistaCamera;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PlayerLaunchFeedback;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitConstraintFeedback;

	UPROPERTY(EditInstanceOnly)
	float BlendTime = 2.0;

	UPROPERTY(EditInstanceOnly)
	float VistaDelay = 1.0;

	UPROPERTY(EditInstanceOnly)
	float VistaBlendTime = 20.0;

	UPROPERTY(EditDefaultsOnly)
	FPostProcessSettings DepthOfFieldSettings;

	TPerPlayer<FSwingPerPlayerData> PlayerData;
	FVector InitialCameraRelativeLocation;

	float FinishBlendTime = -1;
	bool bActivatedVistaCamera = false;

	/* This force will be applied downwards at the location of the player when standing on swing */
	UPROPERTY(EditAnywhere)
	float SmallWeight = 70.0;

	/* This force will be applied downwards at the location of the player when standing on swing */
	UPROPERTY(EditAnywhere)
	float PlayerWeight = 100.0;

	/* This force will be applied downwards at the location of the player when standing on swing */
	UPROPERTY(EditAnywhere)
	float BigWeight = 2000.0;

	UPROPERTY(EditAnywhere)
	float SmallLandImpulse = 50.0;

	/* This impulse will be applied downards at the location of the player when they land */
	UPROPERTY(EditAnywhere)
	float PlayerLandImpulse = 400.0;

	/* This impulse will be applied downards at the location of the big shape when they land */
	UPROPERTY(EditAnywhere)
	float BigLandImpulse = 500.0;

	UPROPERTY(EditAnywhere)
	float BaseLaunchStrength = 3;

	/* This force will be applied upwards on the player when swing reaches top */
	UPROPERTY(EditAnywhere)
	float SmallLaunchImpulseModifier = 1.2;

	/* This force will be applied upwards on the player when swing reaches top */
	UPROPERTY(EditAnywhere)
	float BigLaunchImpulseModifier = 0;

	UPROPERTY(EditAnywhere)
	float AirborneGroundSlamImpulse = 80;

	float AdditionalSlamImpulse = 0;

	float RotationLastFrame = 0;
	float VelocityLastFrame = 0;
	float ImpulseToApply = 0;

	const float MinVelocityForLaunch = 1.5;

	TArray<AHazePlayerCharacter> Players;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	bool bApplyForces = true;
	bool bApplyImpulses = true;

	float RightInteractionExitTime;
	float LeftInteractionExitTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::GetPlayers())
		{
			PlayerData[Player].SwingComp = UTundraPlayerSwingComponent::Get(Player);
			PlayerData[Player].SwingComp.Swing = this;
		}

		InitialCameraRelativeLocation = SwingCamera.RelativeLocation;

		FInteractionCondition InteractCondition;
		InteractCondition.BindUFunction(this, n"CanInteract");

		LeftInteraction.AddInteractionCondition(this, InteractCondition);
		LeftInteraction.OnInteractionStarted.AddUFunction(this, n"OnEntered");

		RightInteraction.AddInteractionCondition(this, InteractCondition);
		RightInteraction.OnInteractionStarted.AddUFunction(this, n"OnEntered");

		FauxAxisRotator.OnMinConstraintHit.AddUFunction(this, n"LaunchMin");
		FauxAxisRotator.OnMaxConstraintHit.AddUFunction(this, n"LaunchMax");
		MovementImpactComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
		MovementImpactComponent.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnGroundImpactEnd");

		GroundSlamResponseComponent.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
	}

	UFUNCTION()
	private EInteractionConditionResult CanInteract(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player)
	{
		if(Time::GetGameTimeSince(PlayerData[Player].StartBlendTime) < 1)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	private void LaunchMax(float Strength)
	{
		TEMPORAL_LOG(this).Event("Max constraint hit");

		AHazePlayerCharacter PlayerToLaunch;
		AHazePlayerCharacter PlayerOnSwing;

		for(auto Player : Players)
		{
			FVector PlayerRelativeLocation = FauxAxisRotator.GetWorldTransform().InverseTransformPosition(Player.ActorLocation);
			if(PlayerRelativeLocation.X < 0)
			{
				PlayerToLaunch = Player;
			}
			else
			{
				PlayerOnSwing = Player;
			}
		}

		ForceFeedback::PlayWorldForceFeedback(HitConstraintFeedback, RightInteraction.WorldLocation, true, this);

		if(PlayerToLaunch != nullptr)
			LaunchPlayer(PlayerToLaunch);
	}

	UFUNCTION()
	private void LaunchMin(float Strength)
	{
		TEMPORAL_LOG(this).Event("Min constraint hit");

		AHazePlayerCharacter PlayerToLaunch;
		AHazePlayerCharacter PlayerOnSwing;

		for(auto Player : Players)
		{
			FVector PlayerRelativeLocation = FauxAxisRotator.GetWorldTransform().InverseTransformPosition(Player.ActorLocation);
			if(PlayerRelativeLocation.X > 0)
			{
				PlayerToLaunch = Player;
			}
			else
			{
				PlayerOnSwing = Player;
			}
		}

		ForceFeedback::PlayWorldForceFeedback(HitConstraintFeedback, LeftInteraction  .WorldLocation, true, this);

		if(PlayerToLaunch != nullptr)
			LaunchPlayer(PlayerToLaunch);
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
		if(!MoveComp.HasGroundContact())
			return;

		if(MoveComp.GroundContact.Actor != this)
			return;

		float FallThreshold = 30;
		if(PlayerData[Player.GetOtherPlayer()].LastFallDistance < FallThreshold)
			return;

		auto ShapeshiftComp = PlayerData[Player].ShapeshiftComp;

		if(ShapeshiftComp == nullptr)
		{
			PlayerData[Player].ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
			ShapeshiftComp = PlayerData[Player].ShapeshiftComp;

			if(PlayerData[Player.OtherPlayer].ShapeshiftComp == nullptr)
				PlayerData[Player.OtherPlayer].ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player.OtherPlayer);
		}

		float FallDistMultiplierBase = (PlayerData[Player.OtherPlayer].LastFallDistance / 3000) * 0.6;
		if(PlayerData[Player.OtherPlayer].ShapeshiftComp.GetActiveShapeType() == ETundraShapeshiftActiveShape::Player)
			FallDistMultiplierBase *= 0.5;
		else if(PlayerData[Player.OtherPlayer].ShapeshiftComp.GetActiveShapeType() == ETundraShapeshiftActiveShape::Small)
			FallDistMultiplierBase = 0;

		float FallDistMultiplier = Math::Pow(1 + FallDistMultiplierBase, 2);

		if(Player.IsZoe())
		{
			ImpulseToApply += AdditionalSlamImpulse;
			AdditionalSlamImpulse = 0;
		}

		float ImpulseModifier = 1;
		if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Small)
			ImpulseModifier = SmallLaunchImpulseModifier;
		else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			ImpulseModifier = BigLaunchImpulseModifier;

		const float FinalImpulse = ImpulseModifier * ImpulseToApply * BaseLaunchStrength * FallDistMultiplier;

		TEMPORAL_LOG(this).Event("Final impulse: " + FinalImpulse);


		if(!Player.HasControl() || !Network::IsGameNetworked())
			CrumbLaunchPlayer(Player, FVector::UpVector * FinalImpulse);
		
		// PlayerData[Player].SwingComp.LastLaunchTime = Time::GameTimeSeconds;
		// Player.AddMovementImpulse(Impulse);
		// PlayerData[Player].SwingComp.ApplyLaunch(Impulse);

		PlayerData[Player].SwingComp.LastLaunchTime = Time::GameTimeSeconds;
		FTundraSwingEventData EventData;
		EventData.Player = Player;
		EventData.ShapeComp = ShapeshiftComp;
		UTundraSeesawSwingEventHandler::Trigger_OnLaunched(this, EventData);

		PlayerData[Player.OtherPlayer].LastFallDistance = 0;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchPlayer(AHazePlayerCharacter Player, FVector Impulse)
	{
		//if(!Player.HasControl())
			//PlayerData[Player].SwingComp.ApplyLaunch(Impulse);

		PlayerData[Player].SwingComp.LastLaunchTime = Time::GameTimeSeconds;
		Player.ResetMovement();
		Player.AddMovementImpulse(Impulse);
		Player.PlayForceFeedback(PlayerLaunchFeedback, false, true, this);
		PlayerData[Player].SwingComp.ApplyLaunch(Impulse);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		Players.AddUnique(Player);

		if(!bApplyImpulses)
			return;

		auto ShapeshiftComp = PlayerData[Player].ShapeshiftComp;

		//if(Player.HasControl())
		{
			PlayerData[Player].LastFallDistance = Player.GetFallingData().StartLocation.Z - Player.GetFallingData().EndLocation.Z;

			const float FallVelocity = -Player.GetFallingData().EndVelocity.Z;
			float MaxVelocity = 3000;
			float VelocityModifier = Math::Saturate(FallVelocity / MaxVelocity);

			float ShapeImpulse = 0;

			if(ShapeshiftComp == nullptr || ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
				ShapeImpulse = PlayerLandImpulse;
			else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
				ShapeImpulse = BigLandImpulse;
			else
				ShapeImpulse = SmallLandImpulse;

			ImpulseToApply = ShapeImpulse * VelocityModifier; 

			const float MaxImpulse = 250;
			ImpulseToApply = Math::Clamp(ImpulseToApply, -MaxImpulse, MaxImpulse);

			FauxAxisRotator.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * ImpulseToApply);
		}

		FTundraSwingEventData EventData;
		EventData.Player = Player;
		EventData.ShapeComp = ShapeshiftComp;
		UTundraSeesawSwingEventHandler::Trigger_OnLanded(this, EventData);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGroundImpactEnd(AHazePlayerCharacter Player)
	{
		Players.Remove(Player);
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType,
	                          FVector PlayerLocation)
	{
		if(!bApplyImpulses)
		{
			AdditionalSlamImpulse = 0;
			return;
		}

		float SlamImpulse = 0;
		
		if(GroundSlamType == ETundraPlayerSnowMonkeyGroundSlamType::Airborne)
			SlamImpulse = AirborneGroundSlamImpulse;


		if(Players.Contains(Game::Zoe))
		{
			FVector PlayerRelativeLocation = FauxAxisRotator.GetWorldTransform().InverseTransformPosition(Game::Zoe.ActorLocation);
			if(PlayerRelativeLocation.X > 0)
			{
				auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
				
				if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
					SlamImpulse *= 0.9;
				else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
					SlamImpulse *= 0.3;
			}
		}

		AdditionalSlamImpulse = SlamImpulse;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		VelocityLastFrame = FauxAxisRotator.Velocity;
		
		FVector TargetLocation = ActorTransform.TransformPositionNoScale(InitialCameraRelativeLocation);
		AHazePlayerCharacter SittingPlayer;
		if(!AreBothPlayersSitting() && IsAnyPlayersSitting(SittingPlayer))
		{
			if(PlayerData[SittingPlayer].InteractionComponent == LeftInteraction)
			{
				TargetLocation += ActorTransform.TransformVectorNoScale(LeftInteraction.RelativeLocation);
			}
			else
			{
				TargetLocation += ActorTransform.TransformVectorNoScale(RightInteraction.RelativeLocation);
			}
		}

		if(AreBothPlayersSitting() && !bActivatedVistaCamera)
		{
			if(Time::GameTimeSeconds > FinishBlendTime)
			{
				for(auto Player : Game::Players)
				{
					Player.ActivateCamera(VistaCamera, VistaBlendTime, FInstigator(this, n"Vista"), EHazeCameraPriority::Low);
					Player.OtherPlayer.ActivateCamera(VistaCamera, VistaBlendTime, FInstigator(this, n"Vista"), EHazeCameraPriority::Low);
				}

				bActivatedVistaCamera = true;
				UTundraSeesawSwingEventHandler::Trigger_OnBothPlayersEntered(this);
			}
		}

		TargetLocation = ActorTransform.InverseTransformPositionNoScale(TargetLocation);
		SwingCamera.SetRelativeLocation(Math::VInterpTo(SwingCamera.RelativeLocation, TargetLocation, DeltaSeconds, 5));


		if(!bApplyForces)
			return;

		for(int i = 0; i < Players.Num(); i++)
		{
			auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Players[i]);

			if(ShapeshiftComp == nullptr || ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
				FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * PlayerWeight);
			else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
				FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * BigWeight);
			else
			{
				//Otter weigh almost as much as human form
				if(Players[i].IsMio())
					FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * (PlayerWeight - 5));
				else
					FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * (SmallWeight));
			}
		}
	}

	UFUNCTION()
	private void OnEntered(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		if(PlayerData[Player].InteractionComponent != nullptr)
			return;

		PlayerData[Player].SwingComp.HorizontalLocation = InteractionComponent.WorldLocation;
		PlayerData[Player].SwingComp.bIsActive = true;
		PlayerData[Player].InteractionComponent = InteractionComponent;
		PlayerData[Player].StartBlendTime = Time::GameTimeSeconds;

		Player.ActivateCamera(SwingCamera, BlendTime, this);

		Player.AddCustomPostProcessSettings(DepthOfFieldSettings, 1, this);

		Player.BlockCapabilities(CapabilityTags::Outline, this);
		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		if(AreBothPlayersSitting())
		{
			Camera::BlendToFullScreenUsingProjectionOffset(Player, this, BlendTime, BlendTime);

			FinishBlendTime = Time::GameTimeSeconds + BlendTime + VistaDelay;
		}

		SetActorTickEnabled(true);

		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"HandleRespawn");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride, EInstigatePriority::High);
	}

	void ExitInteraction(AHazePlayerCharacter Player)
	{
		if(Player.IsPlayerDead())
		{
			return;
		}

		if(AreBothPlayersSitting())
		{
			Player.DeactivateCameraByInstigator(FInstigator(this, n"Vista"), VistaBlendTime / 2);
			Player.OtherPlayer.DeactivateCameraByInstigator(FInstigator(this, n"Vista"), VistaBlendTime / 2);
			Camera::BlendToSplitScreenUsingProjectionOffset(this, BlendTime);

			bActivatedVistaCamera = false;
		}

		PlayerData[Player].SwingComp.bIsActive = false;
		PlayerData[Player].InteractionComponent = nullptr;
		PlayerData[Player].StartBlendTime = Time::GameTimeSeconds;

		Player.DeactivateCameraByInstigator(this);

		Player.RemoveCustomPostProcessSettings(this);

		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.ClearRespawnPointOverride(this);

		AHazePlayerCharacter SittingPlayer;
		if(!IsAnyPlayersSitting(SittingPlayer))
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		OutLocation.RespawnTransform = PlayerData[Player].InteractionComponent.WorldTransform;
		FVector RespawnLocation = OutLocation.RespawnTransform.Location;
		RespawnLocation.Z = ActorLocation.Z + 200;
		OutLocation.RespawnTransform.Location = RespawnLocation;
		
		return true;
	}

	bool AreBothPlayersSitting() const
	{
		for(auto PlayerDatum : PlayerData)
		{
			if(!PlayerDatum.IsSitting())
				return false;
		}

		return true;
	}

	bool IsAnyPlayersSitting(AHazePlayerCharacter&out OutSittingPlayer) const
	{
		for(auto Player : Game::Players)
		{
			auto PlayerDatum = PlayerData[Player];
			if(PlayerDatum.IsSitting())
			{
				OutSittingPlayer = Player;
				return true;
			}
		}

		OutSittingPlayer = nullptr;
		return false;
	}
}