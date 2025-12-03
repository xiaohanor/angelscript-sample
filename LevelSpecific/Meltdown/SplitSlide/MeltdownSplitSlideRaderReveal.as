class AMeltdownSplitSlideRaderReveal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent RaderMeshScifi;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent RaderMeshFantasy;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ThrowObjectScifiRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ThrowObjectFantasyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ThrowableTargetLocation;

	UPROPERTY()
	UNiagaraSystem ExplosionVFXSystem;

	UPROPERTY()
	float ThrowingSpeed = 10000.0;

	UPROPERTY(EditInstanceOnly)
	AMeltdownSplitSlideCollapsingBridge Bridge;

	UPROPERTY(EditInstanceOnly)
	AActor CameraFocusDummyActor;

	bool bThrowing = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RaderMeshFantasy.SetWorldLocationAndRotation(RaderMeshScifi.WorldLocation + FVector::ForwardVector * -500000.0, RaderMeshScifi.WorldRotation);
		ThrowObjectFantasyRoot.SetWorldLocationAndRotation(ThrowObjectScifiRoot.WorldLocation + FVector::ForwardVector * -500000.0, ThrowObjectScifiRoot.WorldRotation);
		CameraFocusDummyActor.SetActorLocation(RaderMeshScifi.WorldLocation + FVector::UpVector * 17000.0);


		if (bThrowing)
		{
			FVector Direction = (ThrowableTargetLocation.WorldLocation - ThrowObjectScifiRoot.WorldLocation).GetSafeNormal();
			ThrowObjectScifiRoot.AddWorldOffset(Direction * DeltaSeconds * ThrowingSpeed);

			if (ThrowObjectScifiRoot.WorldLocation.Distance(ThrowableTargetLocation.WorldLocation) < 500.0)
			{
				Explode();
			}
		}
	}

	UFUNCTION()
	void Throw()
	{	
		bThrowing = true;
		ThrowObjectScifiRoot.DetachFromParent(true);
	}

	UFUNCTION()
	void Explode()
	{
		bThrowing = false;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, ThrowableTargetLocation.WorldLocation);
		ThrowObjectScifiRoot.SetHiddenInGame(true, true);
		ThrowObjectFantasyRoot.SetHiddenInGame(true, true);
		Bridge.Break();

		for (auto Player : Game::Players)
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		}
	}

	UFUNCTION()
	void Activate()
	{
		RaderMeshScifi.SetRelativeLocation(FVector::RightVector * -15000.0);
		RemoveActorDisable(this);
		BossEnter();

		for (auto Player : Game::Players)
		{
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.BlockCapabilities(PlayerMovementTags::Jump, this);
			Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	private void BossEnter()
	{
	}
};