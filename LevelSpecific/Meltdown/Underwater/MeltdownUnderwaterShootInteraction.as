class AMeltdownUnderwaterShootInteraction : AOneShotInteractionActor
{
	UPROPERTY()
	TSubclassOf<AMeltdownUnderwaterIceProjectile> ProjectileClass;
	UPROPERTY(EditInstanceOnly)
	AMeltdownUnderwaterManager Manager;
	UPROPERTY()
	float Cooldown = 0.4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Interaction.OnInteractionStarted.AddUFunction(this, n"OnStartInteraction");
	}

	UFUNCTION()
	private void OnStartInteraction(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		FTransform DisplayTransform = Manager.SceneDisplayActor.ActorTransform;
		FVector RelativePos = DisplayTransform.InverseTransformPosition(Interaction.WorldTransform.TransformPosition(Interaction.WidgetVisualOffset));

		auto DisplayBox = Manager.SceneDisplayActor.GetActorLocalBoundingBox(false);
		
		FVector2D ViewUV;
		ViewUV.X = (RelativePos.Y / DisplayBox.Extent.Y) * 0.5 + 0.5;
		ViewUV.Y = (-RelativePos.Z / DisplayBox.Extent.Z) * 0.5 + 0.5;

		FVector RayOrigin;
		FVector RayDirection;
		Manager.PlayerViews[Player.OtherPlayer].DeprojectViewUVToWorld(
			ViewUV, RayOrigin, RayDirection
		);

		FVector ProjectileLocation = RayOrigin;
		FRotator ProjectileRotation = FRotator::MakeFromX(RayDirection);

		// Trace to whatever we are trying to hit
		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceMio);
		Trace.UseLine();
		auto Hit = Trace.QueryTraceSingle(RayOrigin, RayOrigin + RayDirection * 10000.0);
		if (Hit.bBlockingHit)
		{
			ProjectileRotation = FRotator::MakeFromX(
				Hit.Location - ProjectileLocation
			);
		}

		SpawnActor(
			ProjectileClass,
			ProjectileLocation + ProjectileRotation.ForwardVector * 250.0,
			ProjectileRotation,
		);

		Interaction.Disable(n"Cooldown");
		Timer::SetTimer(this, n"EnableInteraction", Cooldown);
	}

	UFUNCTION()
	private void EnableInteraction()
	{
		Interaction.Enable(n"Cooldown");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Player = Game::Zoe;
		
		if (!Interaction.IsDisabled())
		{
			ActorLocation = Player.ActorLocation + Player.ViewRotation.ForwardVector;
			ActorRotation = FRotator::MakeFromX(Player.ViewRotation.ForwardVector);
			Interaction.WidgetVisualOffset = FVector(100.0, 0.0, 80.0);
		}
	}
};