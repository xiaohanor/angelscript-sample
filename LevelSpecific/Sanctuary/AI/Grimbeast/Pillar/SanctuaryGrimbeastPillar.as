class ASanctuaryGrimbeastPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HoleMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AnticipateMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AnimatedOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = AnimatedOffsetComponent)
	UStaticMeshComponent LavaMeshComp;

	UPROPERTY(DefaultComponent, Attach = AnimatedOffsetComponent)
	UStaticMeshComponent SolidRockMeshComp;

	UPROPERTY(DefaultComponent, Attach = AnimatedOffsetComponent)
	UCapsuleComponent CollisionComponent;

	UPROPERTY(DefaultComponent, Attach = AnimatedOffsetComponent)
	UCapsuleComponent LavaOverlapComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryGrimbeastProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	float SolidifyingDuration = 3.0;
	float SolidifyTimer = 0.0;
	FName MaterialFadeMaskName = n"SphereMaskRadius";

	bool bFreeForAction = true;
	bool bAnticipating = false;
	bool bSolidifying = false;

	const float RaiseOffsetZ = -560;
	FHazeAcceleratedFloat AccHeight;

	float RaiseDuration = 1.0;
	float TargetRaise = 0.6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SolidRockMeshComp.SetVisibility(false);
		LavaMeshComp.SetVisibility(false);
		LavaOverlapComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CollisionComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ProjectileResponseComp.OnProjectileHit.AddUFunction(this, n"OnHit");
	}

	void Raise(float Duration, float HeightMultiplier)
	{
		RaiseDuration = Duration;
		TargetRaise = RaiseOffsetZ * HeightMultiplier;
		StartAnticipating();
	}

	void StartAnticipating()
	{
		USanctuaryGrimbeastPillarEventHandler::Trigger_Anticipate(this, CreateParams());
		Timer::SetTimer(this, n"StartErupt", 1.0);
		bAnticipating = true;
	}

	UFUNCTION()
	void StartErupt()
	{
		bAnticipating = false;
		AccHeight.SnapTo(RaiseOffsetZ);
		AnimatedOffsetComponent.SetRelativeLocation(GetHeightOffset());
		SolidRockMeshComp.SetVisibility(true);
		LavaMeshComp.SetVisibility(true);
		LavaOverlapComponent.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		CollisionComponent.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		bSolidifying = true;
		SolidifyTimer = 0.0;
		USanctuaryGrimbeastPillarEventHandler::Trigger_Erupt(this, CreateParams());
	}

	void Demolish()
	{
		SolidRockMeshComp.SetVisibility(false);
		LavaMeshComp.SetVisibility(false);
		LavaOverlapComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CollisionComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		USanctuaryGrimbeastPillarEventHandler::Trigger_Demolished(this, CreateParams());
		bFreeForAction = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bSolidifying)
		{
			SolidifyTimer += DeltaSeconds;
			float Alpha = Math::Clamp(SolidifyTimer / SolidifyingDuration, 0.0, 1.0);
			float Interpolation = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
			SolidRockMeshComp.SetScalarParameterValueOnMaterials(MaterialFadeMaskName, Interpolation);
			if (Alpha >= 1.0 - KINDA_SMALL_NUMBER)
			{
				bSolidifying = false;
				LavaOverlapComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				USanctuaryGrimbeastPillarEventHandler::Trigger_Solidified(this, CreateParams());
			}
		}

		if (!bAnticipating)
		{
			// PrintToScreen("Acc" + AccHeight.Value);
			AccHeight.AccelerateTo(TargetRaise, 0.5, DeltaSeconds);
			AnimatedOffsetComponent.SetRelativeLocation(GetHeightOffset());
		}
	}

	UFUNCTION()
	private void OnHit(AActor OtherActor)
	{
		auto Fireball = Cast<ASanctuaryGrimbeastBoulderProjectile>(OtherActor);
		if (Fireball != nullptr)
		{
			TargetRaise -= 100.0;
			if (TargetRaise < RaiseOffsetZ + 100.0) // we're working with negatives :)
			{
				TargetRaise = RaiseOffsetZ;
				Demolish();
			}
		}
		auto Iceball = Cast<ASanctuaryCentipedeConsumableProjectile>(OtherActor);
		if (Iceball != nullptr)
			TargetRaise *= 0.5;
	}

	FSanctuaryGrimbeastPillarEventParams CreateParams() const
	{
		FSanctuaryGrimbeastPillarEventParams Data;
		Data.Location = ActorLocation;
		return Data;
	}

	private FVector GetHeightOffset() const
	{
		return FVector(0.0, 0.0, AccHeight.Value);
	}

}