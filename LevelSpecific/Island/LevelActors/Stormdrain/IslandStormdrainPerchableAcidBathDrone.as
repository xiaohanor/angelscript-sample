event void FIslandPerchableAcidBathDroneEvent();

class AIslandStormdrainPerchableAcidBathDrone : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingRoot;
	
	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	USceneComponent RotatingRoot;

	UPROPERTY(DefaultComponent, Attach = RotatingRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent PanelAttachComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent MeshCollider;
	default MeshCollider.RemoveTag(n"Walkable");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent BreakEffect;
	default BreakEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent LoopingBrokenEffect;
	default LoopingBrokenEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent StartRechargeEffect;
	default StartRechargeEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UIslandRedBlueImpactShieldResponseComponent ImpactComp;

	// UPROPERTY(DefaultComponent, Attach = ImpactComp)
	// UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel ShootablePanel;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor KineticMovingActor;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UPerchPointComponent PerchComp;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UPerchEnterByZoneComponent PerchEnterByZoneComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FlipOverAnimation;
	default FlipOverAnimation.Duration = 0.5;

	UPROPERTY(EditInstanceOnly)
	float MoveAnimationSpeed = 1;

	UPROPERTY(EditInstanceOnly)
	float MaxTimeUntilRepaired = 8;
	float TimeUntilRepaired = 0;
	float TimeLastBroken = -100.0;

	UPROPERTY(EditInstanceOnly)
	float MaxDelayBeforePlatformReturnsUp = 2;
	float DelayBeforePlatformReturnsUp = 0;

	UPROPERTY()
	FIslandPerchableAcidBathDroneEvent Broken;

	UPROPERTY()
	FIslandPerchableAcidBathDroneEvent Repaired;

	UPROPERTY()
	FIslandPerchableAcidBathDroneEvent StartRecharge;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	float AmbientMovementCounter = 0;
	
	UPROPERTY(EditInstanceOnly)
	float AmbientMovementAmplitude = 15;

	UPROPERTY(EditInstanceOnly)
	float AmbientMovementDuration = 5;

	float AmbientMovementOffset = 0;

	UPROPERTY(EditDefaultsOnly)
	float SinkSpeed = 50;

	bool bPlayerPerching = false;

	UPROPERTY()
	int MaterialIndex = 1;

	UPROPERTY()
	UMaterialInterface DeactivatedMaterial;

	UPROPERTY()
	UMaterialInterface RechargeMaterial;

	UPROPERTY()
	UMaterialInterface DroneMaterial;

	UMaterialInterface Material;

	UPROPERTY()
	UNiagaraSystem HitEffect;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings ZoeSettings;

	UFUNCTION()
	void TriggerBrokenLoopingSparksEvent(FVector Pos)
	{
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnBrokenLoopingSparks(this, Pos);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(ShootablePanel != nullptr)
		{
			ShootablePanel.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			ShootablePanel.AttachToComponent(PanelAttachComp, AttachmentRule = EAttachmentRule::SnapToTarget);
			ShootablePanel.SetActorRelativeLocation(FVector(0,0,-115));
			ShootablePanel.AddActorLocalRotation(FRotator(0,0,0));
		}

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			Mesh.SetMaterial(MaterialIndex, DroneMaterial);
			ImpactComp.Settings = ZoeSettings;
		}
		
		else
		{
			Mesh.SetMaterial(MaterialIndex, DroneMaterial);
			ImpactComp.Settings = MioSettings;
		}

		if(KineticMovingActor != nullptr)
		{
			KineticMovingActor.ForwardMovementDuration = MoveAnimationSpeed;
			KineticMovingActor.BackwardMovementDuration = MoveAnimationSpeed;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(ShootablePanel != nullptr)
		{
			// ShootablePanel.OverchargeComp.OnImpactOnShield.AddUFunction(this, n"HandleImpact");
			ShootablePanel.OverchargeComp.OnFullCharge.AddUFunction(this, n"HandleFullAlpha");
		}
		PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerPerched");
		PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerching");
		FlipOverAnimation.BindUpdate(this, n"FlipOverUpdate");
		FlipOverAnimation.BindFinished(this, n"FlipOverFinished");
		
		EnableForPlayer(Game::GetPlayer(UsableByPlayer));
		DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer));

		AmbientMovementCounter = Math::RandRange(0.0, AmbientMovementDuration);

		PerchComp.Disable(this);

		if(KineticMovingActor != nullptr)
		{
			KineticMovingActor.OnReachedForward.AddUFunction(this, n"HandleReachedForward");
			KineticMovingActor.OnReachedBackward.AddUFunction(this, n"HandleReachedBackwards");
		}
	}

	UFUNCTION()
	private void FlipOverFinished()
	{
		if(FlipOverAnimation.Value == 1)
		{
			UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnFlipOverFinished(this);
			PerchComp.Enable(this);
		}
	}

	UFUNCTION()
	private void FlipOverUpdate(float CurrentValue)
	{
		RotatingRoot.SetRelativeRotation(FRotator(Math::Lerp(180, 0, CurrentValue),0,0));
	}

	UFUNCTION()
	private void OnPlayerPerched(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnPlayerStartedPerching(this);
		bPlayerPerching = true;

		TranslateRoot.ApplyImpulse(TranslateRoot.WorldLocation, -FVector::UpVector * 50.0);
	}

	UFUNCTION()
	private void OnPlayerStoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnPlayerStoppedPerching(this);
		if(PerchComp.IsPlayerOnPerchPoint[Player.OtherPlayer])
		{
			bPlayerPerching = true;
		}
		else
		{
			bPlayerPerching = false;
		}
	}

	UFUNCTION()
	private void HandleFullAlpha(bool bWasOvercharged)
	{
		ShootablePanel.DisablePanel();
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnImpact(this);
		Mesh.SetMaterial(MaterialIndex, DeactivatedMaterial);
		BreakEffect.Activate(true);
		LoopingBrokenEffect.Activate();
		TranslateRoot.SpringStrength = 1;
		DisableForPlayer(Game::GetPlayer(UsableByPlayer));
		KineticMovingActor.ActivateForward();
		FlipOverAnimation.Play();
		Broken.Broadcast();
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnBroken(this);
		TimeLastBroken = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void HandleReachedForward()
	{
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnReachedForwards(this);
		TimeUntilRepaired = MaxTimeUntilRepaired;
	}

	UFUNCTION()
	void HandleReachedBackwards()
	{
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnReachedBackwards(this);
		Repair();
	}

	UFUNCTION()
	void Repair()
	{
		ShootablePanel.EnablePanel();
		StartRechargeEffect.Activate(true);
		// UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnRechargeVFXSpawn(this);
		StartRechargeEffect.Deactivate();
		EnableForPlayer(Game::GetPlayer(UsableByPlayer));
		ShootablePanel.OverchargeComp.ResetChargeAlpha(this);
		// ImpactComp.ResetShieldAlpha();
		Mesh.SetMaterial(MaterialIndex, Material);
		TranslateRoot.SpringStrength = 5;
		Repaired.Broadcast();
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnRepaired(this);
	}
	
	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactShieldResponseParams ImpactData)
	{
		Niagara::SpawnOneShotNiagaraSystemAttached(HitEffect, Root);
		UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnShieldImpact(this);
	}

	UFUNCTION()
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		// TargetComp.DisableForPlayer(Player, this);
		// ImpactComp.BlockImpactForPlayer(Player, this);
	}

	UFUNCTION()
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		// TargetComp.EnableForPlayer(Player, this);
		// ImpactComp.UnblockImpactForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPlayerPerching)
		{
			TranslateRoot.ApplyForce(TranslateRoot.WorldLocation + (FVector::UpVector * 20.0), -FVector::UpVector * SinkSpeed);
		}
		else
		{
			AmbientMovementCounter += DeltaSeconds;
			if(AmbientMovementCounter > AmbientMovementDuration)
			{
				AmbientMovementCounter -= AmbientMovementDuration;
			}

			float SinMove = Math::Sin((AmbientMovementCounter/AmbientMovementDuration)*PI*2)*AmbientMovementAmplitude * 1.5;
			MovingRoot.SetRelativeLocation(FVector(MovingRoot.RelativeLocation.X,MovingRoot.RelativeLocation.Y,SinMove));
		}


		if(TimeUntilRepaired > 0)
		{
			TimeUntilRepaired -= DeltaSeconds;

			float GameTime = Time::GetGameTimeSeconds();

			float SineRotate = Math::Sin(GameTime * 30) * 1.25;
			Mesh.RelativeRotation = FRotator(Math::Sin(GameTime * 2), 0, Math::Sin(GameTime * 2)) * SineRotate;
			
			if(TimeUntilRepaired <= 2)
			{
				if(!StartRechargeEffect.IsActive())
				{
					StartRechargeEffect.Activate(true);
					UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnRechargeVFXSpawn(this);
					UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnStartRecharge(this);
					StartRecharge.Broadcast();
				}
			}

			if(TimeUntilRepaired <= 0)
			{
				DelayBeforePlatformReturnsUp = MaxDelayBeforePlatformReturnsUp;
			}
		}
		else if(DelayBeforePlatformReturnsUp > 0)
		{
			DelayBeforePlatformReturnsUp -= DeltaSeconds;
			if(DelayBeforePlatformReturnsUp <= 0)
			{
				UIslandStormdrainPerchableAcidBathDroneEventHandler::Trigger_OnFlipOverStarted(this);
				KineticMovingActor.ReverseBackwards();
				FlipOverAnimation.Reverse();
				
				if(PerchComp.IsPlayerOnPerchPoint[Game::GetZoe()])
				{
					// Game::GetZoe().AddKnockbackImpulse(-ActorForwardVector);
					Game::GetZoe().ApplyKnockdown(-ActorForwardVector * 2000);
				}
				else if(PerchComp.IsPlayerOnPerchPoint[Game::GetMio()])
				{
					// Game::GetMio().AddKnockbackImpulse(-ActorForwardVector);
					Game::GetMio().ApplyKnockdown(-ActorForwardVector * 2000);
				}
				
				PerchComp.Disable(this);
				LoopingBrokenEffect.Deactivate();
				Mesh.SetOverlayMaterial(nullptr);
			}
		}

		if(TimeUntilRepaired > 0 || DelayBeforePlatformReturnsUp > 0)
		{
			float GameTime = Time::GetGameTimeSeconds();

			UMaterialInstanceDynamic Recharge_MID = Material::CreateDynamicMaterialInstance(this, RechargeMaterial);
			float MID_PanValue;
			float MID_FresnelValue;

			if(TimeUntilRepaired <= 2)
			{
				MID_PanValue = TimeLastBroken - GameTime * 2;
				//MID_FresnelValue = TimeUntilRepaired;
			}
			else
			{
				MID_PanValue = TimeLastBroken - GameTime;
				//MID_FresnelValue = TimeLastBroken - GameTime * 0.5;
			}

			MID_FresnelValue = Math::Clamp(5 - ((GameTime - TimeLastBroken) * 0.4), 0, 10);

			Recharge_MID.SetScalarParameterValue(n"Z_Pan", MID_PanValue);
			Recharge_MID.SetScalarParameterValue(n"Fresnel_Exp", MID_FresnelValue);
			Mesh.SetOverlayMaterial(Recharge_MID);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsBroken() const
	{
		return Time::GetGameTimeSince(TimeLastBroken) <= KineticMovingActor.ForwardMovementDuration || TimeUntilRepaired > 0.0;
	}

	UFUNCTION(BlueprintPure)
	float GetTimeToRepaired() const
	{
		if(!IsBroken())
			return -1.0;

		float TimeSinceBroken = Time::GetGameTimeSince(TimeLastBroken);
		return KineticMovingActor.ForwardMovementDuration + MaxTimeUntilRepaired - TimeSinceBroken;
	}
}