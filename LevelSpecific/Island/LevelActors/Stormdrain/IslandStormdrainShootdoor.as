event void FIslandStormdrainShootDoor();

class AIslandStormdrainShootdoor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingDoorZoeRoot;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent DoorFrame;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingDoorMioRoot;

	UPROPERTY(DefaultComponent, Attach = "MovingDoorZoeRoot")
	UStaticMeshComponent DoorMeshZoe;

	UPROPERTY(DefaultComponent, Attach = "MovingDoorMioRoot")
	UStaticMeshComponent DoorMeshMio;

	UPROPERTY(DefaultComponent, Attach = "DoorMeshZoe")
	UStaticMeshComponent ShootMeshZoe;

	UPROPERTY(DefaultComponent, Attach = "DoorMeshMio")
	UStaticMeshComponent ShootMeshMio;

	UPROPERTY(DefaultComponent, Attach = "ShootMeshZoe")
	UIslandRedBlueImpactCounterResponseComponent ImpactCompZoe;
	default ImpactCompZoe.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = "ShootMeshMio")
	UIslandRedBlueImpactCounterResponseComponent ImpactCompMio;
	default ImpactCompMio.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	// UPROPERTY(DefaultComponent, Attach = "ShootMeshZoe")
	// UIslandRedBlueTargetableComponent TargetZoe;

	// UPROPERTY(DefaultComponent, Attach = "ShootMeshMio")
	// UIslandRedBlueTargetableComponent TargetMio;

	UPROPERTY(EditInstanceOnly)
	float SmallMovementOffset = 20;

	UPROPERTY(EditInstanceOnly)
	float OpenDoorOffset = 330;

	UPROPERTY()
	FHazeTimeLike SmallMovementAnimation;	
	default SmallMovementAnimation.Duration = 0.3;
	default SmallMovementAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default SmallMovementAnimation.Curve.AddDefaultKey(0.3, 1.0);

	UPROPERTY()
	FHazeTimeLike OpenDoorAnimation;	
	default OpenDoorAnimation.Duration = 2;
	default OpenDoorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default OpenDoorAnimation.Curve.AddDefaultKey(2.0, 1.0);

	UPROPERTY()
	bool bZoeDestroyed = false;
	UPROPERTY()
	bool bMioDestroyed = false;
	UPROPERTY()
	bool bDoorOpen = false;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel RedPanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel BluePanelRef;

	FVector ZoeDoorStartLerp = FVector(0,0,0);
	FVector MioDoorStartLerp = FVector(0,0,0);

	UPROPERTY()
	FIslandStormdrainShootDoor MioFinished;

	UPROPERTY()
	FIslandStormdrainShootDoor ZoeFinished;

	UPROPERTY()
	FIslandStormdrainShootDoor DoorOpen;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent SmallOpenEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent SmallCloseEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent FullyOpenEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent FullyCloseEvent = nullptr;

	UPROPERTY(BlueprintHidden)
	FHazeAudioFireForgetEventParams Params;
	default Params.AttenuationScaling = 8000;
	default Params.Transform = Root.GetWorldTransform();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		if(RedPanelRef != nullptr)
		{
			RedPanelRef.OnOvercharged.AddUFunction(this, n"HandleImpactRed");
			RedPanelRef.OnReset.AddUFunction(this, n"HandleRedReset");
		}
		if(BluePanelRef != nullptr)
		{
			BluePanelRef.OnOvercharged.AddUFunction(this, n"HandleImpactBlue");
			BluePanelRef.OnReset.AddUFunction(this, n"HandleBlueReset");
		}

		ImpactCompMio.BlockImpactForPlayer(Game::GetZoe(), this);
		ImpactCompZoe.BlockImpactForPlayer(Game::GetMio(), this);
		// TargetZoe.DisableForPlayer(Game::GetMio(), this);
		// TargetMio.DisableForPlayer(Game::GetZoe(), this);

		SmallMovementAnimation.BindUpdate(this, n"SmallMovementUpdate");
		SmallMovementAnimation.BindFinished(this, n"SmallMovementFinished");
		OpenDoorAnimation.BindUpdate(this, n"OpenDoorUpdate");
	}

	UFUNCTION()
	private void HandleBlueReset()
	{
		if(bDoorOpen)
			return;

		ResetDoor();
	}

	UFUNCTION()
	private void HandleRedReset()
	{
		if(bDoorOpen)
			return;
		
		ResetDoor();
	}

	UFUNCTION()
	void ResetDoor()
	{
		if(!HasControl())
			return;

		CrumbResetDoor();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetDoor()
	{
		SmallMovementAnimation.Reverse();
		AudioComponent::PostFireForget(SmallCloseEvent, Params);
	}

	UFUNCTION()
	private void SmallMovementFinished()
	{
		if(SmallMovementAnimation.Position == 0)
		{
			bZoeDestroyed = false;
			bMioDestroyed = false;
		}
	}

	UFUNCTION()
	void SmallMovementUpdate(float CurveValue)
	{
		float TargetPosition = CurveValue * SmallMovementOffset;
		if(bZoeDestroyed)
		{
			ZoeDoorStartLerp = FVector(0, -TargetPosition, 0);
			MovingDoorZoeRoot.SetRelativeLocation(ZoeDoorStartLerp);
		}
		if(bMioDestroyed)
		{
			MioDoorStartLerp = FVector(0, TargetPosition, 0);
			MovingDoorMioRoot.SetRelativeLocation(MioDoorStartLerp);
		}
	}



	UFUNCTION()
	void OpenDoorUpdate(float CurveValue)
	{
		float TargetPosition = CurveValue * OpenDoorOffset;

		//Math::GetMappedRangeValueClamped(FVector2D(ZoeDoorStartLerp, ))

		//float ZoeLerp = -TargetPosition;
		//float MioLerp = TargetPosition;

		float ZoeLerp = Math::GetMappedRangeValueClamped(FVector2D(0, OpenDoorOffset), FVector2D(ZoeDoorStartLerp.Y, -OpenDoorOffset), TargetPosition);
		float MioLerp = Math::GetMappedRangeValueClamped(FVector2D(0, OpenDoorOffset), FVector2D(MioDoorStartLerp.Y, OpenDoorOffset), TargetPosition);

		MovingDoorZoeRoot.SetRelativeLocation(FVector(0, ZoeLerp, 0));
		MovingDoorMioRoot.SetRelativeLocation(FVector(0, MioLerp, 0));
		
	}

	UFUNCTION()
	void HandleImpactBlue()
	{
		AHazePlayerCharacter Player = Game::GetZoe();
		bZoeDestroyed = true;
		ShootMeshZoe.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ShootMeshZoe.SetHiddenInGame(true, false);
		ImpactCompZoe.BlockImpactForPlayer(Game::GetZoe(), this);
		// TargetZoe.DisableForPlayer(Game::GetZoe(), this);

		ZoeFinished.Broadcast();

		if(bMioDestroyed)
		{
			Open();
		}
		else
		{
			SmallMovement();
		}
	}

	UFUNCTION()
	void HandleImpactRed()
	{
		AHazePlayerCharacter Player = Game::GetZoe();
		bMioDestroyed = true;
		ShootMeshMio.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ShootMeshMio.SetHiddenInGame(true, false);
		ImpactCompMio.BlockImpactForPlayer(Game::GetMio(), this);
		// TargetMio.DisableForPlayer(Game::GetMio(), this);

		MioFinished.Broadcast();

		if(bZoeDestroyed)
		{
			Open();
		}
		else
		{
			SmallMovement();
		}
	}

	UFUNCTION()
	void SmallMovement()
	{
		if(!HasControl())
			return;

		CrumbSmallMovement();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSmallMovement()
	{
		SmallMovementAnimation.Play();
		AudioComponent::PostFireForget(SmallOpenEvent, Params);
	}

	UFUNCTION()
	void Open()
	{
		if(!HasControl())
			return;

		CrumbOpen();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOpen()
	{
		SmallMovementAnimation.Stop();
		OpenDoorAnimation.Play();
		DoorOpen.Broadcast();

		RedPanelRef.SetCompleted();
		BluePanelRef.SetCompleted();

		bDoorOpen = true;

		AudioComponent::PostFireForget(FullyOpenEvent, Params);
	}

	UFUNCTION()
	void Close()
	{
		if(!HasControl())
			return;

		CrumbClose();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbClose()
	{
		ZoeDoorStartLerp = FVector::ZeroVector;
		MioDoorStartLerp = FVector::ZeroVector;
		OpenDoorAnimation.Reverse();

		bDoorOpen = false;

		AudioComponent::PostFireForget(FullyCloseEvent, Params);
	}
}