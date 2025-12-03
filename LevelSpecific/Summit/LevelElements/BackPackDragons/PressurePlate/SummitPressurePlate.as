class ASummitPressurePlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent OnButtonTrigger;

	UPROPERTY(DefaultComponent)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetCastShadows(false);
	default SpotLight.OuterConeAngle = 30.0;
	default SpotLight.bUseInverseSquaredFalloff = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly)
	ASummitPressurePlate PlateSibling;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveMat;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect RumbleOn;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect RumbleOff;

	UPROPERTY(EditAnywhere)
	float PlayerTeleportBackMinDistance = 500.0;

	UPROPERTY(EditAnywhere)
	float ButtonPressedOffset = 20.0;

	UPROPERTY(EditAnywhere)
	float ButtonPressedSpeed = 8.0;

	UPROPERTY(EditInstanceOnly)
	bool bIsTheParent;

	UPROPERTY(BlueprintReadOnly)
	bool bMioOn;
	UPROPERTY(BlueprintReadOnly)
	bool bZoeOn;
	UPROPERTY(BlueprintReadOnly)
	bool bIsPressed;
	UPROPERTY(BlueprintReadOnly)
	bool bIsCompleted;
	bool bIsMoving = false;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor Color;
	float DefaultLightIntensity;

	TPerPlayer<bool> BlockedFloorSlowdown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnButtonTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnButtonTriggerOverlapped");
		OnButtonTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnButtonTriggerOverlapEnd");
		DefaultLightIntensity = SpotLight.Intensity;
	}

	UFUNCTION()
	private void OnButtonTriggerOverlapped(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		ToggleFloorSlowdownBlock(Player, true);

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = true;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = true;

		if (bIsPressed)
			return;

		bIsPressed = true;
		BP_OnOverlap();
		Activated();

		USummitPressurePlateEventHandler::Trigger_OnButtonStartedGoingDown(this);
		bIsMoving = true;

		Player.PlayForceFeedback(RumbleOn, false, false, this);
	}

	UFUNCTION()
	private void OnButtonTriggerOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;
		
		ToggleFloorSlowdownBlock(Player, false);

		if (bIsCompleted)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = false;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = false;

		if(bMioOn == false && bZoeOn == false)
			bIsPressed = false;

		if (!bIsPressed)
			BP_OnEndOverlap();
		
		USummitPressurePlateEventHandler::Trigger_OnButtonStartedGoingUp(this);
		bIsMoving = true;

		Player.PlayForceFeedback(RumbleOff, false, false, this, 0.1);
	}

	UFUNCTION()
	void Activated()
	{		
		if (bIsCompleted)
			return;

		if (PlateSibling == nullptr)
			return;
		
		if (!bIsTheParent)
		{
			PlateSibling.Activated();
			return;
		}
			

		if(!HasControl())
			return;

		if (bIsPressed == true && PlateSibling.bIsPressed == true)
		{
			CrumbActivated();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(auto Player : Game::Players)
		{
			if(BlockedFloorSlowdown[Player])
			{
				ToggleFloorSlowdownBlock(Player, false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto Player : Game::Players)
		{
			if(BlockedFloorSlowdown[Player])
			{
				ToggleFloorSlowdownBlock(Player, false);
			}
		}
	}

	void ToggleFloorSlowdownBlock(AHazePlayerCharacter Player, bool bBlock)
	{
		if(bBlock)
		{
			if(BlockedFloorSlowdown[Player])
				return;

			Player.BlockCapabilities(PlayerFloorMotionTags::FloorMotionSlowdown, this);
			BlockedFloorSlowdown[Player] = true;
		}
		else
		{
			if(!BlockedFloorSlowdown[Player])
				return;

			Player.UnblockCapabilities(PlayerFloorMotionTags::FloorMotionSlowdown, this);
			BlockedFloorSlowdown[Player] = false;
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivated()
	{
		bIsCompleted = true;
		PlateSibling.bIsCompleted = true;
		BP_OnActivated();

		MoveBackPlayersIfTooFarAway();
	}

	void MoveBackPlayersIfTooFarAway()
	{
		for(auto Player : Game::Players)
		{
			if(Player.HasControl())
			{
				float DistanceToPlate = Player.ActorLocation.DistSquared(ActorLocation);
				if(DistanceToPlate < Math::Square(PlayerTeleportBackMinDistance))
					 continue;

				float DistanceToPlateSibling = Player.ActorLocation.DistSquared(PlateSibling.ActorLocation);
				if(DistanceToPlateSibling < Math::Square(PlayerTeleportBackMinDistance))
					continue;

				ASummitPressurePlate PlateToTeleportTo = DistanceToPlate < DistanceToPlateSibling 
					? this 
					: PlateSibling;

				CrumbTeleportPlayerToButton(Player, PlateToTeleportTo);
			}	
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbTeleportPlayerToButton(AHazePlayerCharacter PlayerToTeleport, ASummitPressurePlate Plate)
	{
		PlayerToTeleport.SmoothTeleportActor(Plate.ActorLocation, PlayerToTeleport.ActorRotation, this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMoving)
		{
			FVector TargetLocation = GetButtonTargetLocation();
			MoveRoot.RelativeLocation = Math::VInterpTo(MoveRoot.RelativeLocation, TargetLocation, DeltaSeconds, ButtonPressedSpeed);

			FVector DeltaToTarget = TargetLocation - MoveRoot.RelativeLocation;
			if(DeltaToTarget.IsNearlyZero(1.0))
			{
				MoveRoot.RelativeLocation = TargetLocation;
				bIsMoving = false;
				if(bIsPressed)
					USummitPressurePlateEventHandler::Trigger_OnButtonStoppedGoingDown(this);
				else	
					USummitPressurePlateEventHandler::Trigger_OnButtonStoppedGoingUp(this);
			}
		}

	}

	private FVector GetButtonTargetLocation() const
	{
		if(bIsPressed)
			return FVector::DownVector * ButtonPressedOffset;
		else
			return FVector::ZeroVector;
	}

	UFUNCTION()
	void SetEmissiveMaterial(UStaticMeshComponent MeshComp, bool bIsOn)
	{
		if (DynamicMat == nullptr)
		{
			DynamicMat = MeshComp.CreateDynamicMaterialInstance(0);
			Color = DynamicMat.GetVectorParameterValue(n"Tint_D_Emissive");
		}

		if (bIsOn)
		{
			DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 15.0);
			SpotLight.SetIntensity(DefaultLightIntensity);
		}
		else
		{
			DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 0.05);
			SpotLight.SetIntensity(0.0);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, PlayerTeleportBackMinDistance);	
	}
#endif

	UFUNCTION(BlueprintEvent)
	void BP_OnOverlap(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnEndOverlap(){}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}
};