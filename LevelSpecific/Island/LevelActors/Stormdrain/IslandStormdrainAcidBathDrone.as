event void FIslandAcidBathDroneEvent();

class AIslandStormdrainAcidBathDrone : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = "MovingRoot")
	UStaticMeshComponent Mesh;
	default Mesh.RemoveTag(n"Walkable");

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UNiagaraComponent BreakEffect;
	default BreakEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UNiagaraComponent LoopingBrokenEffect;
	default LoopingBrokenEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UIslandRedBlueImpactShieldResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = "ImpactComp")
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor KineticMovingActor;

	UPROPERTY(EditInstanceOnly)
	AIslandFloatingPlatform FloatingPlatform;

	UPROPERTY(EditInstanceOnly)
	float MaxTimeUntilRepaired = 10;
	float TimeUntilRepaired = 0;

	UPROPERTY(EditInstanceOnly)
	float MaxDelayBeforePlatformReturnsUp = 2;
	float DelayBeforePlatformReturnsUp = 0;

	UPROPERTY()
	FIslandAcidBathDroneEvent Broken;

	UPROPERTY()
	FIslandAcidBathDroneEvent Repaired;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;

	float AmbientMovementCounter = 0;
	
	UPROPERTY(EditInstanceOnly)
	float AmbientMovementAmplitude = 15;

	UPROPERTY(EditInstanceOnly)
	float AmbientMovementDuration = 5;

	float AmbientMovementOffset = 0;

	UPROPERTY()
	int MaterialIndex = 1;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface DeactivatedMaterial;

	UMaterialInterface Material;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings ZoeSettings;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			Mesh.SetMaterial(MaterialIndex, ZoeMaterial);
			ImpactComp.Settings = ZoeSettings;
		}
		
		else
		{
			Mesh.SetMaterial(MaterialIndex, MioMaterial);
			ImpactComp.Settings = MioSettings;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnImpactOnShield.AddUFunction(this, n"HandleImpact");
		ImpactComp.OnImpactWhenShieldDestroyed.AddUFunction(this, n"HandleFullAlpha");
		
		EnableForPlayer(Game::GetPlayer(UsableByPlayer));
		DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer));

		AmbientMovementCounter = Math::RandRange(0.0, AmbientMovementDuration);

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			Material = ZoeMaterial;
		}
		
		else
		{
			Material = MioMaterial;
		}

		Mesh.SetMaterial(MaterialIndex, Material);
		if(KineticMovingActor != nullptr)
		{
			KineticMovingActor.OnReachedForward.AddUFunction(this, n"HandleReachedForward");
			KineticMovingActor.OnReachedBackward.AddUFunction(this, n"HandleReachedBackwards");
		}
	}

	UFUNCTION()
	void HandleFullAlpha(FIslandRedBlueImpactShieldResponseParams ImpactData)
	{
		Mesh.SetMaterial(MaterialIndex, DeactivatedMaterial);
		BreakEffect.Activate(true);
		LoopingBrokenEffect.Activate(true);
		DisableForPlayer(Game::GetPlayer(UsableByPlayer));
		KineticMovingActor.ActivateForward();
		FloatingPlatform.SetPerchPointActive(true);
		Broken.Broadcast();
	}

	UFUNCTION()
	void HandleReachedForward()
	{
		TimeUntilRepaired = MaxTimeUntilRepaired;
	}

	UFUNCTION()
	void HandleReachedBackwards()
	{
	}

	UFUNCTION()
	void Repair()
	{
		LoopingBrokenEffect.Deactivate();
		EnableForPlayer(Game::GetPlayer(UsableByPlayer));
		ImpactComp.ResetShieldAlpha();
		Mesh.SetMaterial(MaterialIndex, Material);
		Repaired.Broadcast();
	}
	
	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactShieldResponseParams ImpactData)
	{
		BreakEffect.Activate(true);
	}

	UFUNCTION()
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		TargetComp.DisableForPlayer(Player, this);
		ImpactComp.BlockImpactForPlayer(Player, this);
	}

	UFUNCTION()
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		TargetComp.EnableForPlayer(Player, this);
		ImpactComp.UnblockImpactForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AmbientMovementCounter += DeltaSeconds;
		if(AmbientMovementCounter > AmbientMovementDuration)
		{
			AmbientMovementCounter -= AmbientMovementDuration;
		}

		MovingRoot.SetRelativeLocation(FVector(0,0,Math::Sin((AmbientMovementCounter/AmbientMovementDuration)*PI*2)*AmbientMovementAmplitude));

		if(TimeUntilRepaired > 0)
		{
			TimeUntilRepaired -= DeltaSeconds;

			FloatingPlatform.SetCountdownProgress(TimeUntilRepaired / MaxTimeUntilRepaired);

			if(TimeUntilRepaired <= 0)
			{
				Repair();
				DelayBeforePlatformReturnsUp = MaxDelayBeforePlatformReturnsUp;
				FloatingPlatform.TriggerWarningAnimation(MaxDelayBeforePlatformReturnsUp);
			}
		}

		else if(DelayBeforePlatformReturnsUp > 0)
		{
			DelayBeforePlatformReturnsUp -= DeltaSeconds;
			if(DelayBeforePlatformReturnsUp <= 0)
			{
				KineticMovingActor.ReverseBackwards();
				FloatingPlatform.SetPerchPointActive(false);
			}
		}
	}
}