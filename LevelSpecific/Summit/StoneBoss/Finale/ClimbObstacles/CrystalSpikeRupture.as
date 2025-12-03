event void FOnCrystalSpikeRuptureDestroyed();

class USpikeRuptureVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USpikeRuptureVisualizerDudComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SpikeRupture = Cast<ACrystalSpikeRupture>(Component.Owner);

		if (SpikeRupture == nullptr)
			return;

		// FVector DrawLocation = SpikeRupture.Root.WorldLocation + (SpikeRupture.ActorUpVector * (SpikeRupture.LocalOffsetTarget.Z / 2));
		// DrawWireBox(DrawLocation, SpikeRupture.BoxComp.BoundingBoxExtents, SpikeRupture.ActorRotation.Quaternion(), FLinearColor::Red, 2);
	}
}

class USpikeRuptureVisualizerDudComponent : UActorComponent
{

}

class USummitCrystalSpikeRuptureCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ACrystalSpikeRupture SpikeRupture;

	FVector StartLocation;

	float DelayTime = 1.0;
	float MoveDuration = 0;

	bool bRupture = false;
	bool bTelepgraphOn = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpikeRupture = Cast<ACrystalSpikeRupture>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SpikeRupture.bRuptureEndState)
			return false;

		if (!SpikeRupture.bIsActivated)
			return false;

		if (SpikeRupture.bWasDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > MoveDuration + DelayTime)
			return true;

		if (SpikeRupture.bWasDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpikeRupture.DetachInstigators.Remove(n"NotRuptured");
		SpikeRupture.UpdateDetach();

		StartLocation = SpikeRupture.SpikeRoot.RelativeLocation;
		float MoveDistance = StartLocation.Distance(SpikeRupture.TargetLoc);
		MoveDuration = MoveDistance / SpikeRupture.RuptureSpeed;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(SpikeRupture.CameraShake, this);

		SpikeRupture.RuptureSystem.Activate();
		SpikeRupture.KillTrigger.EnableTrigger(n"NotRuptured");
		if (SpikeRupture.bBlockOnly)
			SpikeRupture.KillTrigger.EnableTrigger(SpikeRupture);
		SpikeRupture.DisableLinkedRespawnPoint();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpikeRupture.SetSpikeRuptureEndState();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SpikeRupture.SpikeRoot.RelativeLocation = Math::VInterpConstantTo(SpikeRupture.SpikeRoot.RelativeLocation, SpikeRupture.TargetLoc, DeltaTime, 1500.0);
	}
}

class ACrystalSpikeRupture : AHazeActor
{
	default SetActorHiddenInGame(true);

	UPROPERTY()
	FOnCrystalSpikeRuptureDestroyed OnCrystalSpikeRuptureDestroyed; 

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpikeRoot;

	UPROPERTY(DefaultComponent, Attach = SpikeRoot)
	USceneComponent SpikeMeshRoot;

	UPROPERTY(DefaultComponent, Attach = SpikeMeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	// UPROPERTY(DefaultComponent, Attach = SpikeMeshRoot)
	// UBoxComponent BoxComp;
	// default BoxComp.bDisableUpdateOverlapsOnComponentMove = true;
	// default BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	// default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	// default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = SpikeMeshRoot)
	UHazeMovablePlayerTriggerComponent KillTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent RuptureSystem;
	default RuptureSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalSpikeRuptureCapability");

	UPROPERTY(EditAnywhere)
	ARespawnPointVolume LinkedRespawnVolume;

	UPROPERTY(EditAnywhere)
	float Offset = -500;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bDrawDisableRange = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	ACrystalSpikeRuptureManager Manager;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	FVector TargetLoc;

	UPROPERTY(EditAnywhere)
	float DelayTime = 1.5;

	UPROPERTY(EditAnywhere)
	float MaxTelegraphTime = 1.5;

	UPROPERTY(EditAnywhere)
	bool bBlockOnly;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinScale = 0.9;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxScale = 1.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PitchRange = 10.0;

	UPROPERTY(EditAnywhere)
	bool bLeaveAfterManagerDisable = false;

	float RuptureSpeed = 2500.0;

	bool bRupture;
	bool bTelepgraphOn;
	bool bRuptureEndState;

	bool bIsActivated = false;
	bool bWasDestroyed;

	FTransform TransformBeforeDetach;

	TArray<FInstigator> DetachInstigators;
	bool bIsDetached = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		AddActorDisable(n"Not Started");
		DisableComp.SetEnableAutoDisable(false);

		if (Manager != nullptr)
		{
			TargetLoc = SpikeRoot.RelativeLocation;
			SpikeRoot.RelativeLocation += FVector(0, 0, Offset);
		}

		KillTrigger.DisableTrigger(n"NotRuptured");
		if (bBlockOnly)
		{
			MeshComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
			KillTrigger.DisableTrigger(this);
		}
		else
		{
			if (Manager != nullptr && !Manager.bCanKillPlayersBehindSpawnDistance)
			{
				KillTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterKillTrigger");
			}
			else
			{
				KillTrigger.DisableTrigger(this);
			}
		}

		if (Manager != nullptr)
			Manager.AddRuptureToDataSet(this);

		DetachInstigators.Add(n"NotRuptured");
		UpdateDetach();
	}

	UFUNCTION(CallInEditor)
	void RandomizeSpikeRuptureAppearance()
	{
		SpikeMeshRoot.RelativeRotation = FRotator(0, Math::RandRange(0, 359), 0);
		// SpikeMeshRoot.RelativeRotation += FRotator(Math::RandRange(0, PitchRange), 0, 0);
		SpikeMeshRoot.RelativeScale3D = FVector(Math::RandRange(MinScale, MaxScale));
	}

	UFUNCTION(CallInEditor)
	void ResetSpikeRupturePitchAndRoll()
	{
		SpikeRoot.RelativeRotation = FRotator(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		DetachInstigators.AddUnique(n"Disabled");
		UpdateDetach();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		DetachInstigators.Remove(n"Disabled");
		UpdateDetach();
	}

	void UpdateDetach()
	{
		if (bIsDetached)
		{
			if (DetachInstigators.IsEmpty())
			{
				if (Root.AttachParent != nullptr)
				{
					// Start moving with the parent again
					Root.SetAbsolute(false, false, false);
					Root.SetRelativeTransform(TransformBeforeDetach);
				}

				bIsDetached = false;
			}
		}
		else
		{
			if (!DetachInstigators.IsEmpty())
			{
				if (Root.AttachParent != nullptr)
				{
					// Stop moving with the parent when disabled
					TransformBeforeDetach = GetActorRelativeTransform();

					FTransform PrevWorldTransform = GetActorTransform();
					Root.SetAbsoluteAndUpdateTransform(true, true, true, PrevWorldTransform);
				}

				bIsDetached = true;
			}
		}
	}

	UFUNCTION()
	void ActivateSpikeRupture()
	{
		if (bWasDestroyed)
			return;

		bIsActivated = true;

		RemoveActorDisable(n"Not Started");
		DisableComp.SetEnableAutoDisable(true);

		UCrystalSpikeRuptureEventHandler::Trigger_OnSpikeRuptureStarted(this, FOnSpikeRuptureStartedParams(SpikeRoot.WorldLocation));
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void SetSpikeRuptureEndState()
	{
		if (bWasDestroyed)
			return;

		DisableLinkedRespawnPoint();

		SpikeRoot.RelativeLocation = TargetLoc;
		bRuptureEndState = true;
		SetActorHiddenInGame(false);

		RemoveActorDisable(n"Not Started");
		DisableComp.SetEnableAutoDisable(true);

		KillTrigger.EnableTrigger(n"NotRuptured");
		KillTrigger.EnableTrigger(this);
		KillTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterKillTrigger");

		DetachInstigators.Remove(n"NotRuptured");
		UpdateDetach();
	}

	void WeakpointDestroyRupture()
	{
		if (bWasDestroyed)
			return;

		bWasDestroyed = true;
		AddActorDisable(this);
		OnCrystalSpikeRuptureDestroyed.Broadcast();
	}

	void DisableLinkedRespawnPoint()
	{
		if (LinkedRespawnVolume != nullptr)
			LinkedRespawnVolume.DisableRespawnPointVolume(this);
	}

	// UFUNCTION()
	// private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	// 							 UPrimitiveComponent OtherComp, int OtherBodyIndex,
	// 							 bool bFromSweep, const FHitResult&in SweepResult)
	// {
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
	// 	if (Player != nullptr)
	// 	{
	// 		if (!Player.IsPlayerDead() && !Player.IsPlayerRespawning())
	// 			Player.KillPlayer(FPlayerDeathDamageParams(FVector::UpVector, 10.0), DeathEffect);
	// 	}
	// 	auto Critter = Cast<AAISummitStoneBeastCritter>(OtherActor);
	// 	if (Critter != nullptr)
	// 	{
	// 		if (!Critter.HealthComp.IsDying())
	// 			Damage::AITakeDamage(Critter, 100, this);
	// 	}
	// }

	UFUNCTION()
	private void OnPlayerEnterKillTrigger(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(FPlayerDeathDamageParams(FVector::UpVector, 10.0), DeathEffect);
	}
};