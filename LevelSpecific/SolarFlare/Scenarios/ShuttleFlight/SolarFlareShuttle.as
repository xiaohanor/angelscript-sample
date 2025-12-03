class ASolarFlareShuttle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.bGenerateOverlapEvents = false;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default BoxComp.SetCollisionObjectType(ECollisionChannel::PlayerCharacter);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent YawRoot;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	USceneComponent PitchRoot;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	USceneComponent ShootOrigin;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	UStaticMeshComponent HookMesh;
	default HookMesh.SetHiddenInGame(true);

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UNiagaraComponent ThrusterLeft;
	// UPROPERTY(DefaultComponent, Attach = Root)
	// UNiagaraComponent ThrusterRight;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere)
	AShuttleFlightCameraActor Camera;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ActivateShieldCameraShake;

	UPROPERTY()
	UHazeCapabilitySheet MioSheet;
	UPROPERTY()
	UHazeCapabilitySheet ZoeSheet;

	float CameraBlendIn = 0.5;

	void ActivateShield()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(ActivateShieldCameraShake, this, 0.5);

		HookMesh.SetHiddenInGame(false);
	}

	void DeactivateShield()
	{
		HookMesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	void ActivateShuttleControls(AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(Camera, CameraBlendIn, this);
		
		if (Player == Game::Mio)
		{
			Player.StartCapabilitySheet(MioSheet, this);
		}
		else
		{
			Player.StartCapabilitySheet(ZoeSheet, this);
		}
	}

	UFUNCTION()
	void DeactivateShuttleControls(AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(Camera);

		if (Player == Game::Mio)
		{
			Player.StopCapabilitySheet(MioSheet, this);
		}
		else
		{
			Player.StopCapabilitySheet(ZoeSheet, this);
		}	
			
		//Probably activate cutscene in level BP?
	}
}