event void FOnSkylineInnerCityBoxSlingRecyclePlz();
event void FOnSkylineInnerCityBoxSlingLanded();

class ASkylineInnerCityBoxSling : AWhipSlingableObject
{	
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshSlingbox;

	UPROPERTY(DefaultComponent)
	USceneComponent DoorPivot;

	UPROPERTY(DefaultComponent,Attach = DoorPivot)
	UStaticMeshComponent Door;

	UPROPERTY(DefaultComponent, Attach = MeshSlingbox)
	USceneComponent TelportLoc;

	UPROPERTY(DefaultComponent, Attach = MeshSlingbox)
	USceneComponent ExitLoc;

	UPROPERTY(DefaultComponent)
	UBoxComponent KillBoxCollision;

	UPROPERTY()
	FHazeTimeLike Timelike;

	UPROPERTY(EditAnywhere)
	FText CustomCancelText;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(EditDefaultsOnly, Category = "ForceFeedback")
	UForceFeedbackEffect GrabbedForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "ForceFeedback")
	UForceFeedbackEffect ThrownForceFeedback;

	UPROPERTY(DefaultComponent, Attach = MeshSlingbox)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	FOnSkylineInnerCityBoxSlingRecyclePlz OnSkylineInnerCityBoxSlingRecyclePlz;
	UPROPERTY(EditAnywhere)
	FOnSkylineInnerCityBoxSlingLanded OnSkylineInnerCityBoxSlingLanded;

	USkylineInnerCityBoxSlingPlayerComponent BoxedComp = nullptr;

	AHazePlayerCharacter BoxedPlayer;

	default bDestroyOnImpact = true;
	default LifeTimeAfterThrown = 0.0;
	float SpecialCaseLifeTimeAfterThrown = 5.0;
	bool bMioIsForSureInBox = false;
	bool bDoOnce = true;
	
	UPROPERTY(EditAnywhere)
	UNiagaraSystem RespawnEffect;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Timelike.BindUpdate(this, n"HandleAnimationUpdate");
		Timelike.BindFinished(this, n"HandleAnimationFinished");
		//InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleInteraction");
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteraction");
		InteractionComp.OnCancelPressed.AddUFunction(this, n"HandleStopped");
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"HandleOnThrowned");
		KillBoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandlePlayerCrushed");
		OnDestroyed.AddUFunction(this, n"BoxDed");

		MeshSlingbox.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		Door.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		StartLocation = ActorLocation;
		PlayerCollisionRadius = 200.0;
		InteractionComp.Disable(this);
	}

	UFUNCTION()
	private void HandlePlayerCrushed(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                 const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Player.KillPlayer();
	}

	UFUNCTION()
	private void HandleAnimationUpdate(float CurrentValue)
	{
		DoorPivot.RelativeRotation = FRotator(0.0, CurrentValue * 100, 0.0);
	}

	UFUNCTION()
	private void HandleAnimationFinished()
	{
		if(bDoOnce)
			InteractionComp.Enable(this);

		bDoOnce = false;
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		Timelike.Reverse();
		InterfaceComp.TriggerActivate();
		InteractionComp.Disable(this);
		OnSkylineInnerCityBoxSlingRecyclePlz.Broadcast();

			if (BoxedComp != nullptr)
			{
				if(BoxedComp.bIsBoxed)
				{
					bMioIsForSureInBox = true;
					Game::Mio.PlayForceFeedback(GrabbedForceFeedback, false, false, this, 1);
					InteractionComp.BlockCancelInteraction(BoxedPlayer, this);
				}
			}
	}

	UFUNCTION()
	private void HandleOnThrowned(UGravityWhipUserComponent UserComponent,
	                              UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                              FVector Impulse)
	{
		if (BoxedComp != nullptr)
			{
				if(BoxedComp.bIsBoxed)
					Game::Mio.PlayForceFeedback(ThrownForceFeedback, false, false, this, 1);
			}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Debug::DrawDebugSolidPlane(StartLocation, FVector::UpVector, 10000, 10000);
		Super::Tick(DeltaSeconds);
		if (BoxedComp != nullptr)
			BoxedComp.bCanExit = !bThrown && !bGrabbed;
		if (bThrown)
		{
			SpecialCaseLifeTimeAfterThrown -= DeltaSeconds;
			bool bKillBeneathPlaneHax = BoxedPlayer != nullptr && BoxedPlayer.ActorLocation.Z < StartLocation.Z;
			if (SpecialCaseLifeTimeAfterThrown < 0.0 || bKillBeneathPlaneHax)
			{
				if (BoxedComp != nullptr && BoxedComp.Owner != nullptr)
				{
					if (BoxedComp.Owner.HasControl())
						CrumbDestroyBox();
				}
				else
				{
					if (HasControl())
						CrumbDestroyBox();
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDestroyBox()
	{
		if (BoxedComp != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(BoxedComp.Owner);
			if (Player != nullptr)
				Player.KillPlayer();
		}

		InteractionComp.KickAnyPlayerOutOfInteraction();
		DestroyActor();
	}

	UFUNCTION()
	private void HandleInteraction(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		BoxedPlayer = Player;

		auto MoveComp = UPlayerMovementComponent::Get(BoxedPlayer);
		MoveComp.AddMovementIgnoresActor(this, this);

		this.bCanDamagePlayer = false;
		InteractionComp.Disable(this);
		
		CloseDoorAnimatiom();
		BoxedComp = USkylineInnerCityBoxSlingPlayerComponent::GetOrCreate(Player);
		BoxedComp.bIsBoxed = true;
		BoxedComp.Boxy = this;
		UPlayerHealthComponent PlayerHealth = UPlayerHealthComponent::Get(Player);
		PlayerHealth.OnStartDying.AddUFunction(this, n"BoxedPlayerDied");

		BoxedPlayer.AttachToActor(this);
		//BoxedPlayer.TeleportActor(TelportLoc.GetWorldLocation(), TelportLoc.GetWorldRotation(), this, false);
		//BoxedPlayer.SmoothTeleportActor(TelportLoc.GetWorldLocation(), TelportLoc.GetWorldRotation(),this, 1.0);
		
		BoxedPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		BoxedPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		BoxedPlayer.BlockCapabilities(n"PlayerShadow", this);
		BoxedPlayer.BlockCapabilities(n"PvPDamage", this);
	}

	UFUNCTION()
	private void HandleStopped(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		UnboxPlayer();
	}

	UFUNCTION()
	void BoxDed(AActor Destoryed)
	{
		
		if (BoxedComp != nullptr)
		{
			UnboxPlayer();
			Game::Mio.SnapToGround();
			Game::Mio.ApplyKnockdown(MeshSlingbox.ForwardVector * 100, 1.0);
		}
			
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorCenterLocation, ActorRotation);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		if(BoxedPlayer!=nullptr)
			InteractionComp.UnblockCancelInteraction(BoxedPlayer, this);
	}

	UFUNCTION()
	void BoxedPlayerDied()
	{
		if (BoxedComp != nullptr)
			UnboxPlayer();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorCenterLocation, ActorRotation);
		if (!bGrabbed && !bThrown) // player died inside static box. Can happen if mio is inside and zoe throws other items at her
			OnSkylineInnerCityBoxSlingRecyclePlz.Broadcast();
		DestroyActor();
	}

	void UnboxPlayer()
	{
		if (BoxedComp == nullptr)
			return;

		this.bCanDamagePlayer = true;
		PlayDoorAnimation();
		if (BoxedPlayer.HasControl())
			Timer::SetTimer(this, n"CrumbDelayedEnableInteract", 0.75);
		UPlayerHealthComponent MioHealth = UPlayerHealthComponent::Get(BoxedPlayer);
		MioHealth.OnStartDying.Unbind(this, n"BoxedPlayerDied");
		BoxedPlayer.DetachFromActor();
		BoxedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		BoxedPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		BoxedPlayer.UnblockCapabilities(n"PlayerShadow", this);
		BoxedPlayer.UnblockCapabilities(n"PvPDamage", this);
		BoxedComp.bIsBoxed = false;
		BoxedComp.bCanExit = false;
		BoxedComp.Boxy = nullptr;
		BoxedComp = nullptr;

		if(bMioIsForSureInBox)
			InteractionComp.KickAnyPlayerOutOfInteraction();
		
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDelayedEnableInteract()
	{
		InteractionComp.Enable(this);
		//	MeshSlingbox.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
		//Door.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
		//Door.SetCollisionProfileName(n"BlockAllDynamic");
		//MeshSlingbox.SetCollisionProfileName(n"BlockAllDynamic");
		auto MoveComp = UPlayerMovementComponent::Get(BoxedPlayer);
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION()
	void PlayDoorAnimation()
	{
	

		//Timelike.SetPlayRate(2.0);
		Timelike.Play();
		BP_OpenDoorAnimation();
	}

	UFUNCTION()
	void CloseDoorAnimatiom()
	{
		

		//Timelike.SetPlayRate(1.0);
		Timelike.Reverse();
		BP_CloseDoorAnimation();
	}
	
	void DeactivateDeathBox()
	{
		KillBoxCollision.SetGenerateOverlapEvents(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_CloseDoorAnimation(){}

	UFUNCTION(BlueprintEvent)
	void BP_OpenDoorAnimation(){}
};