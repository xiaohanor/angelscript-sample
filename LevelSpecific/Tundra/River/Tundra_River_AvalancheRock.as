event void TundraRiverAvalancheRockEvent();

class ATundra_River_AvalancheRock : AKineticSplineFollowActor
{
	UPROPERTY()
	TundraRiverAvalancheRockEvent StartedMoving;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	USceneComponent ShakeComp;

	UPROPERTY(DefaultComponent, Attach = ShakeComp)
	UFauxPhysicsConeRotateComponent FPConeRotationComp;
	default FPConeRotationComp.ForceScalar = 0.5;
	default FPConeRotationComp.Friction = 20;
	default FPConeRotationComp.SpringStrength = 0.1;
	default FPConeRotationComp.ConeAngle = 10;
	default FPConeRotationComp.ConstrainBounce = 0;

	UPROPERTY(DefaultComponent, Attach = FPConeRotationComp)
	UStaticMeshComponent MeshToStandOn;

	UPROPERTY(DefaultComponent, Attach = MeshToStandOn)
	UPlayerInheritMovementComponent PlayerInheritMovement;
	default PlayerInheritMovement.DeactivationType = EPlayerInheritMovementDeactivationType::OutsideShape;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FPPlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent VFXTransform;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_AvalancheRespawnPoint RespawnPoint;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger Trigger;

	bool bTriggered = false;
	bool bHasSetRespawnPoint = false;
	bool bHasDisabledRespawnPoint = false;
	UPROPERTY(EditInstanceOnly)
	float DisableRespawnPointAtDistanceFromEnd = 2000;

	UPROPERTY(EditInstanceOnly)
	bool bCheckDistance = false;

	default DesiredFollowSpeed = 900;
	default bAutoActivate = false;

	UPROPERTY()
	FHazeTimeLike ShakeAnimationRoll;
	default ShakeAnimationRoll.Duration = 5;
	default ShakeAnimationRoll.bLoop = true;

	UPROPERTY()
	FHazeTimeLike ShakeAnimationPitch;
	default ShakeAnimationPitch.Duration = 8;
	default ShakeAnimationPitch.bLoop = true;

	float CurrentPitch = 0;
	float MaxPitch = 1;
	float CurrentRoll = 0;
	float MaxRoll = 1;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerReachEndEffects = true;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UPROPERTY()
	UHazeCapabilitySheet MioActionIdleAnimationSheet;
	
	UPROPERTY()
	UHazeCapabilitySheet ZoeActionIdleAnimationSheet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		if(Trigger != nullptr)
		{
			Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		}

		ShakeAnimationRoll.BindUpdate(this, n"TL_ShakeAnimationRollUpdate");
		ShakeAnimationPitch.BindUpdate(this, n"TL_ShakeAnimationPitchUpdate");
		
		PlayerInheritMovement.OnPlayerEnter.AddUFunction(this, n"HandleOnPlayerEnter");
		PlayerInheritMovement.OnPlayerLeave.AddUFunction(this, n"HandleOnPlayerLeave");

		if(RespawnPoint != nullptr)
		{
			RespawnPoint.OnRespawnAtRespawnPoint.AddUFunction(this, n"PlayerRespawned");
		}

		OnReachedEnd.AddUFunction(this, n"HandleOnReachedEnd");
		if(RespawnPoint != nullptr)
		{
			RespawnPoint.AttachToComponent(MeshToStandOn, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		}
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawningPlayer)
	{
		RespawningPlayer.SetActorVelocity(FVector::ZeroVector);
	}

	UFUNCTION()
	private void TL_ShakeAnimationPitchUpdate(float CurrentValue)
	{
		CurrentPitch = CurrentValue * MaxPitch;
	}

	UFUNCTION()
	private void TL_ShakeAnimationRollUpdate(float CurrentValue)
	{
		CurrentRoll = CurrentValue * MaxRoll;
		//ShakeComp.SetRelativeRotation(FRotator(CurrentPitch, 0, CurrentRoll));
	}

	UFUNCTION()
	private void HandleOnPlayerLeave(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);
	
		if(Player == Game::GetMio())
		{
			Player.StopCapabilitySheet(MioActionIdleAnimationSheet, this);
		}

		else
		{
			Player.StopCapabilitySheet(ZoeActionIdleAnimationSheet, this);
		}
		
	}

	UFUNCTION()
	private void HandleOnReachedEnd()
	{
		if(bTriggerReachEndEffects)
		{
			UTundra_River_AvalancheRock_EffectHandler::Trigger_ReachedEnd(this);
		}

		UTundra_River_AvalancheRock_EffectHandler::Trigger_StopMoving(this);
		SetActorHiddenInGame(true);
		for(auto Player : OverlappingPlayers)
		{
			Player.KillPlayer();
		}
		ShakeAnimationRoll.Stop();
		ShakeAnimationPitch.Stop();
	}

	UFUNCTION()
	private void HandleOnPlayerEnter(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.AddUnique(Player);
		if(Player == Game::GetMio())
		{
			Player.StartCapabilitySheet(MioActionIdleAnimationSheet, this);
		}
		else
		{
			Player.StartCapabilitySheet(ZoeActionIdleAnimationSheet, this);
		}

		if(RespawnPoint != nullptr
		&& !bHasSetRespawnPoint)
		{
			bHasSetRespawnPoint = true;
			Player.SetStickyRespawnPoint(RespawnPoint);
			Player.GetOtherPlayer().SetStickyRespawnPoint(RespawnPoint);
		}
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if(!bTriggered)
		{
			bTriggered = true;
			StartMoving();
		}
	}

	UFUNCTION()
	void StartMoving()
	{
		StartedMoving.Broadcast();
		UTundra_River_AvalancheRock_EffectHandler::Trigger_StartMoving(this);
		ActivateFollowSpline();
		ShakeAnimationRoll.PlayFromStart();
		ShakeAnimationPitch.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if(!bHasDisabledRespawnPoint && RespawnPoint != nullptr)
		{
			float DistanceToEnd = GetActorLocation().Distance(SplineToFollow.Spline.GetWorldLocationAtSplineDistance(SplineToFollow.Spline.GetSplineLength()));
			if(DistanceToEnd < DisableRespawnPointAtDistanceFromEnd)
			{
				bHasDisabledRespawnPoint = true;
				UPlayerRespawnComponent::Get(Game::Mio).ClearStickyRespawnPoint(RespawnPoint);
				UPlayerRespawnComponent::Get(Game::Zoe).ClearStickyRespawnPoint(RespawnPoint);
				PrintToScreen("DisableRespawn", 5, FLinearColor::Red);
			}

			if(bCheckDistance)
				PrintToScreen(""+DistanceToEnd, 0, FLinearColor::Red);
		}
	}
};