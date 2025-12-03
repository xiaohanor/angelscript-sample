struct FPlantLauncherAnimData
{
	float Weight = 0;
	bool bIsLaunched = false;
	bool bFailedLaunch = false;
	ELaunchPadWeightMode WeightMode = ELaunchPadWeightMode::None;
}

enum ELaunchPadWeightMode
{
	None,
	Small,
	Large
}

UCLASS(Abstract)
class ATundraCrackLaunchpad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach=SkeletalMesh, AttachSocket="Stalk6")
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTundraCrackLaunchpadVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

	UPROPERTY(EditAnywhere)
	float MaxVerticalForce = 300000.0;

	UPROPERTY(EditAnywhere)
	float MaxVerticalForceAcceleration = 80000.0;

	UPROPERTY(EditAnywhere)
	float OtterHeightToReach = 900.0;

	UPROPERTY(EditAnywhere)
	float PlayerHeightToReach = 600.0;

	UPROPERTY(EditAnywhere)
	float SnowMonkeyHeightToReach = 250.0;

	float CurrentVerticalForce;
	bool bImpulseHasBeenApplied = true;
	UPlayerMovementComponent MioMoveComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;
	default MovementImpactCallbackComp.bTriggerLocally = false;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;

	FPlantLauncherAnimData AnimData;

	float TargetHeight;
	float LastTargetHeight;
	FHazeAcceleratedFloat CurrentHeight;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedHeight;

	float PullSpeed = 1;

	float DistToLaunch = 0.0;

	float LaunchTime;
	bool bFloorMotionBlocked = false;
	float VerticalInput = 0.0;

	TPerPlayer<UTundraPlayerShapeshiftingComponent> PlayersOnLaunchpad;

	// Audio
	UPROPERTY(DefaultComponent, Category = "Audio", Attach = MeshComp)
	UHazeAudioComponent AudioComp;

	private ELaunchPadWeightMode LastWeightMode = ELaunchPadWeightMode::None;

	UFUNCTION(BlueprintEvent)
	void OnPlayerLand(ELaunchPadWeightMode NewWeightMode) {}

	UFUNCTION(BlueprintEvent)
	void OnWeightModeChanged(ELaunchPadWeightMode NewWeightMode) {}

	UFUNCTION(BlueprintEvent)
	void OnStartCharge() {}

	UFUNCTION(BlueprintEvent)
	void OnStopCharge() {}

	UFUNCTION(BlueprintEvent)
	void OnLaunch() {}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		MioMoveComp = UPlayerMovementComponent::Get(Game::Mio);
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"RegisterPlayer");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
			SetActorControlSide(Game::Zoe);

		PlayersOnLaunchpad[Player] = nullptr;
		AnimData.WeightMode = ELaunchPadWeightMode::None;
	}

	UFUNCTION()
	private void RegisterPlayer(AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
			SetActorControlSide(Game::Mio);

		PlayersOnLaunchpad[Player] = UTundraPlayerShapeshiftingComponent::Get(Player);
		OnPlayerLand(AnimData.WeightMode);
	}

	void CheckPlayerType()
	{
		AnimData.WeightMode = ELaunchPadWeightMode::None;

		for(auto Player : PlayersOnLaunchpad)
		{
			if(Player == nullptr)
				continue;

			if(AnimData.WeightMode == ELaunchPadWeightMode::Large)
				return;

			if(Player.CurrentShapeType == ETundraShapeshiftShape::Small)
				AnimData.WeightMode = ELaunchPadWeightMode::Small;

			else if(Player.CurrentShapeType == ETundraShapeshiftShape::Player)
				AnimData.WeightMode = ELaunchPadWeightMode::Small;

			else if(Player.CurrentShapeType == ETundraShapeshiftShape::Big)
				AnimData.WeightMode = ELaunchPadWeightMode::Large;
		}

		if(AnimData.WeightMode != LastWeightMode)
		{
			OnWeightModeChanged(AnimData.WeightMode);
		}

		LastWeightMode = AnimData.WeightMode;
	}

	float GetLaunchDistance(UTundraPlayerShapeshiftingComponent Player)
	{
		if(Player.CurrentShapeType == ETundraShapeshiftShape::Small)
			return OtterHeightToReach;
		
		else if(Player.CurrentShapeType == ETundraShapeshiftShape::Big)
			return SnowMonkeyHeightToReach;

		return PlayerHeightToReach;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckPlayerType();
		
		if(bFloorMotionBlocked && Time::GetGameTimeSince(LaunchTime) >= 0.5)
		{
			Game::Mio.UnblockCapabilities(PlayerMovementTags::FloorMotion, this);
			bFloorMotionBlocked = false;
		}

		if(Game::Zoe.HasControl())
		{
			float TempVerticalInput = LifeGivingActor.LifeReceivingComponent.GetRawVerticalInput();

			if(TempVerticalInput < -0.2) 
				TempVerticalInput = -1.0;
			else
				TempVerticalInput = 0.0;

			if(TempVerticalInput != VerticalInput)
				NetSetVerticalInput(TempVerticalInput);
		}

		if(HasControl() || (Game::Zoe.HasControl() && VerticalInput == -1.0))
		{
			if(HasControl())
			{
				if(CurrentHeight.Value < -0.9 && TargetHeight < 0 && VerticalInput == 0)
				{
					if(HasTreeGuardian())
						FailToLaunch();
					else
					{
						Game::Zoe.PlayForceFeedback(ForceFeedback::Default_Medium, this);
						CrumbSetIsLaunched(true);
					}
				}
				else if(AnimData.bIsLaunched)
				{
					CrumbSetIsLaunched(false);
				}
			}

			TargetHeight = VerticalInput;
			CurrentHeight.AccelerateTo(TargetHeight, PullSpeed, DeltaTime);
			SyncedHeight.Value = CurrentHeight.Value;
		}
		else
		{
			CurrentHeight.Value = SyncedHeight.Value;
		}

		// Audio
		if(TargetHeight != LastTargetHeight)
		{
			if(TargetHeight == -1)
				OnStartCharge();
			else if(!AnimData.bIsLaunched)
				OnStopCharge();
			else	
				OnLaunch();
		}	

		AnimData.Weight = -CurrentHeight.Value;
		AnimData.bFailedLaunch = false;
		LastTargetHeight = TargetHeight;
	}

	UFUNCTION(NetFunction)
	private void NetSetVerticalInput(float Input)
	{
		VerticalInput = Input;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetIsLaunched(bool bInLaunched)
	{
		AnimData.bIsLaunched = bInLaunched;
	}

	void Launch()
	{
		CrumbSetIsLaunched(true);

		if(AnimData.WeightMode == ELaunchPadWeightMode::None)
			return;

		if(HasControl())
			CrumbLaunch(PlayersOnLaunchpad);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch(TPerPlayer<UTundraPlayerShapeshiftingComponent> PlayersToLaunch)
	{
		for(auto Player : PlayersToLaunch)
		{
			if(Player == nullptr)
				continue;
			
			if(Player.Player.IsMio())
			{
				bFloorMotionBlocked = true;
				Game::Mio.BlockCapabilities(PlayerMovementTags::FloorMotion, this);
			}

			Player.Player.PlayForceFeedback(ForceFeedback::Default_Medium_Short, this);
			Player.Player.AddMovementImpulseToReachHeight(GetLaunchDistance(Player), true, n"TundraCrackLaunchpadImpulse");
		}
		
		LaunchTime = Time::GameTimeSeconds;
	}

	private void FailToLaunch()
	{
		AnimData.bFailedLaunch = true;
	}

	bool HasTreeGuardian()
	{
		if(PlayersOnLaunchpad[Game::GetZoe()] != nullptr)
			return PlayersOnLaunchpad[Game::GetZoe()].CurrentShapeType == ETundraShapeshiftShape::Big;

		return false;
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UTundraCrackLaunchpadVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraCrackLaunchpadVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraCrackLaunchpadVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Launchpad = Cast<ATundraCrackLaunchpad>(Component.Owner);
		FBox LocalBounds = Launchpad.GetActorLocalBoundingBox(true);
		FVector LocalTopOfBounds = LocalBounds.Center + FVector::UpVector * LocalBounds.Extent.Z;
		FVector PlayerOriginLocation = Launchpad.ActorTransform.TransformPosition(LocalTopOfBounds);

		DrawPoint(PlayerOriginLocation, FLinearColor::LucBlue, 20.0);

		FVector2D MonkeyCollision = TundraShapeshiftingStatics::SnowMonkeyCollisionSize;
		FVector2D PlayerCollision = FVector2D(32.0, 82.0);
		FVector2D OtterCollision = TundraShapeshiftingStatics::OtterCollisionSize;

		DrawShapeCapsule(PlayerOriginLocation, Launchpad.ActorRotation, OtterCollision, Launchpad.OtterHeightToReach, FLinearColor::DPink, "Otter");
		DrawShapeCapsule(PlayerOriginLocation, Launchpad.ActorRotation, PlayerCollision, Launchpad.PlayerHeightToReach, FLinearColor::Purple, "Player");
		DrawShapeCapsule(PlayerOriginLocation, Launchpad.ActorRotation, MonkeyCollision, Launchpad.SnowMonkeyHeightToReach, FLinearColor::LucBlue, "Monkey");
	}

	void DrawShapeCapsule(FVector PlayerOriginLocation, FRotator CapsuleRotation, FVector2D CollisionSize, float HeightToReach, FLinearColor Color, FString String)
	{
		
		FVector OtterCenterLocation = PlayerOriginLocation + FVector::UpVector * (HeightToReach + CollisionSize.Y);
		DrawWireCapsule(OtterCenterLocation, CapsuleRotation, Color, CollisionSize.X, CollisionSize.Y, 6, 5.0);
		DrawWorldString(String, OtterCenterLocation, Color, 1.5, -1.0, false, true);
	}
}
#endif