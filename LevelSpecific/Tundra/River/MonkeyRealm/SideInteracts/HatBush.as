UCLASS(Abstract)
class AHatBush : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BushRoot;

	UPROPERTY(DefaultComponent, Attach = BushRoot)
	UStaticMeshComponent BushMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraShapeshiftingInteractionComponent ShapeshiftInteractComp;

	UPROPERTY(DefaultComponent, Attach = BushRoot)
	UNiagaraComponent FallingLeavesVFX;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams AnimParamsMh;

	UPROPERTY(EditDefaultsOnly)
	float ShrinkDuration = 10;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem LeafExplosionVFX;

	float ShrinkTimer;
	bool bAttached = false;
	float TimeStarted;
	AHazePlayerCharacter AttachedPlayer;
	UPlayerMovementComponent AttachedPlayerMoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShapeshiftInteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		ShapeshiftInteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractStopped");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bAttached)
		{
			if(AttachedPlayer != nullptr)
			{
				if(AttachedPlayer.GetActorVelocity().Size() > 0.1)
				{
					ShrinkTimer -= DeltaSeconds;
				}
				else
				{
					ShrinkTimer -= DeltaSeconds * 0.2;
				}

				float ScaleAlpha = Math::GetPercentageBetweenClamped(ShrinkDuration, 0, ShrinkTimer);
				FVector LerpedScale = FVector(1, 1, 1) * Math::Lerp(2, 1, ScaleAlpha);
				BushMesh.SetWorldScale3D(LerpedScale);

				if(ShrinkTimer <= 0)
				{
					Niagara::SpawnOneShotNiagaraSystemAtLocation(LeafExplosionVFX, ActorLocation);
					DestroyActor();
				}
			} 
		}
	}

	UFUNCTION()
	private void OnInteractStopped(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(n"GameplayAction", this);
		Player.StopAllSlotAnimations();

		UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftComp.RemoveShapeTypeBlockerInstigator(this);

		if(bAttached)
			return; 

		ShapeshiftComp.OnChangeShape.Unbind(this, n"OnChangeShape");

		// Player.AddMovementImpulse((FVector::UpVector + -ActorForwardVector) * 900);

		UTundra_River_InteractableBushEffectHandler::Trigger_OnPlayerExitBush(Player);
	}

	UFUNCTION()
	private void OnInteractStarted(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		Player.BlockCapabilitiesExcluding(n"GameplayAction", n"Shapeshifting", this);
		
		UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftComp.AddShapeTypeBlocker(ETundraShapeshiftShape::Small, this);
		ShapeshiftComp.OnChangeShape.AddUFunction(this, n"OnChangeShape");

		UTundra_River_InteractableBushEffectHandler::Trigger_OnPlayerHideInBush(Player);

		Player.PlaySlotAnimation(AnimParamsMh);
	}

	UFUNCTION()
	private void OnChangeShape(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape)
	{
		if(NewShape == ETundraShapeshiftShape::Big)
		{
			UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
			ShapeshiftInteractComp.KickAnyPlayerOutOfInteraction();
			ShapeshiftInteractComp.Disable(this);
			AttachToComponent(ShapeshiftComp.BigShapeComponent.GetShapeMesh(), n"Head");
			BushMesh.SetRelativeScale3D(FVector(2, 2 ,2));
			FallingLeavesVFX.Activate(true);
			ShrinkTimer = ShrinkDuration;
			TimeStarted = Time::GetGameTimeSeconds();
			AttachedPlayer = Player;
			
			if (Player.IsMio())
				UTundra_River_InteractableBushEffectHandler::Trigger_OnSnowMonkeyPutOnBushHat(this);
			
			if (Player.IsZoe())
				UTundra_River_InteractableBushEffectHandler::Trigger_OnTreeGuardianPutOnBushHat(this);

			bAttached = true;
		}

		if(bAttached && NewShape != ETundraShapeshiftShape::Big)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(LeafExplosionVFX, ActorLocation);
			UTundra_River_InteractableBushEffectHandler::Trigger_OnBushHatGetsDestroyed(Player);
			DestroyActor();
		}
	}
};
