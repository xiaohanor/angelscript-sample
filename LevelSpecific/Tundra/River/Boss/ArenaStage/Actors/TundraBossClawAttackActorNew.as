class ATundraBossClawAttackActorNew : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw01Root;

	UPROPERTY(DefaultComponent, Attach = Claw01Root)
	UNiagaraComponent Claw01FX;
	default Claw01FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw01Root)
	UHazeMovablePlayerTriggerComponent Claw01KillBox;
	default Claw01KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw02Root;

	UPROPERTY(DefaultComponent, Attach = Claw02Root)
	UNiagaraComponent Claw02FX;
	default Claw02FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw02Root)
	UHazeMovablePlayerTriggerComponent Claw02KillBox;
	default Claw02KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw03Root;

	UPROPERTY(DefaultComponent, Attach = Claw03Root)
	UNiagaraComponent Claw03FX;
	default Claw03FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw03Root)
	UHazeMovablePlayerTriggerComponent Claw03KillBox;
	default Claw03KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw04Root;

	UPROPERTY(DefaultComponent, Attach = Claw04Root)
	UNiagaraComponent Claw04FX;
	default Claw04FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw04Root)
	UHazeMovablePlayerTriggerComponent Claw04KillBox;
	default Claw04KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw05Root;

	UPROPERTY(DefaultComponent, Attach = Claw05Root)
	UNiagaraComponent Claw05FX;
	default Claw05FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw05Root)
	UHazeMovablePlayerTriggerComponent Claw05KillBox;
	default Claw05KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw06Root;

	UPROPERTY(DefaultComponent, Attach = Claw06Root)
	UNiagaraComponent Claw06FX;
	default Claw06FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw06Root)
	UHazeMovablePlayerTriggerComponent Claw06KillBox;
	default Claw06KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw07Root;

	UPROPERTY(DefaultComponent, Attach = Claw07Root)
	UNiagaraComponent Claw07FX;
	default Claw07FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw07Root)
	UHazeMovablePlayerTriggerComponent Claw07KillBox;
	default Claw07KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw08Root;

	UPROPERTY(DefaultComponent, Attach = Claw08Root)
	UNiagaraComponent Claw08FX;
	default Claw08FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw08Root)
	UHazeMovablePlayerTriggerComponent Claw08KillBox;
	default Claw08KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw09Root;

	UPROPERTY(DefaultComponent, Attach = Claw09Root)
	UNiagaraComponent Claw09FX;
	default Claw09FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw09Root)
	UHazeMovablePlayerTriggerComponent Claw09KillBox;
	default Claw09KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Claw10Root;

	UPROPERTY(DefaultComponent, Attach = Claw10Root)
	UNiagaraComponent Claw10FX;
	default Claw10FX.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Claw10Root)
	UHazeMovablePlayerTriggerComponent Claw10KillBox;
	default Claw10KillBox.Shape = FHazeShapeSettings::MakeBox(FVector(85.0, 90.0, 750.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	UForceFeedbackComponent FFComp;

	UPROPERTY(EditInstanceOnly)
	FTransform ClawRelativeTransform;

	UPROPERTY(EditInstanceOnly)
	ATundraBossClawAttackCamShakeActor ClawAttackCamShakeActorMio;
	UPROPERTY(EditInstanceOnly)
	ATundraBossClawAttackCamShakeActor ClawAttackCamShakeActorZoe;

	UPROPERTY()
	TSubclassOf<UDamageEffect> ClawAttackDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> ClawAttackDeathEffect;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float ClawSpeed = 2000;
	TArray<USceneComponent> MeshRoots;
	TArray<UNiagaraComponent> FxComps;
	TArray<FVector> ComponentDir;
	TArray<UHazeMovablePlayerTriggerComponent> KillBoxes;
	TArray<FVector> StartLocs;
	
	FVector Claw01StartLoc;
	FVector Claw02StartLoc;
	FVector Claw03StartLoc;
	FVector Claw04StartLoc;
	FVector Claw05StartLoc;
	FVector Claw06StartLoc;

	float ActiveTimer = 0;
	float ActiveTimerDuration = 5;
	bool bShouldTickActiveTimer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRoots.Add(Claw01Root);
		MeshRoots.Add(Claw02Root);
		MeshRoots.Add(Claw03Root);
		MeshRoots.Add(Claw04Root);
		MeshRoots.Add(Claw05Root);
		MeshRoots.Add(Claw06Root);
		MeshRoots.Add(Claw07Root);
		MeshRoots.Add(Claw08Root);
		MeshRoots.Add(Claw09Root);
		MeshRoots.Add(Claw10Root);

		KillBoxes.Add(Claw01KillBox);
		KillBoxes.Add(Claw02KillBox);
		KillBoxes.Add(Claw03KillBox);
		KillBoxes.Add(Claw04KillBox);
		KillBoxes.Add(Claw05KillBox);
		KillBoxes.Add(Claw06KillBox);
		KillBoxes.Add(Claw07KillBox);
		KillBoxes.Add(Claw08KillBox);
		KillBoxes.Add(Claw09KillBox);
		KillBoxes.Add(Claw10KillBox);

		FxComps.Add(Claw01FX);
		FxComps.Add(Claw02FX);
		FxComps.Add(Claw03FX);
		FxComps.Add(Claw04FX);
		FxComps.Add(Claw05FX);
		FxComps.Add(Claw06FX);
		FxComps.Add(Claw07FX);
		FxComps.Add(Claw08FX);
		FxComps.Add(Claw09FX);
		FxComps.Add(Claw10FX);

		for(int i = 0; i < MeshRoots.Num(); i++)
			ComponentDir.Add(FVector::ZeroVector);

		for(auto Box : KillBoxes)
			Box.OnPlayerEnter.AddUFunction(this, n"OnKillBoxOverlap");

		for(int i = 0; i < MeshRoots.Num(); i++)
			StartLocs.Add(MeshRoots[i].RelativeLocation);

		SetCollisionBoxesEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bShouldTickActiveTimer)
			return;

		ActiveTimer += DeltaSeconds;

		if(ActiveTimer >= ActiveTimerDuration)
		{
			DeactivateClawAttack();
			bShouldTickActiveTimer = false;
		}
	
		for(int i = 0; i < MeshRoots.Num(); i++)
		{
			FVector NewLocation = MeshRoots[i].WorldLocation + MeshRoots[i].ForwardVector * ClawSpeed * DeltaSeconds;
			FVector Velo = (NewLocation - MeshRoots[i].WorldLocation) / DeltaSeconds;
			MeshRoots[i].SetWorldLocation(NewLocation);
			ComponentDir[i] = Velo.GetSafeNormal2D();
		}

		FHazeRuntimeSpline CurrentSpline = FHazeRuntimeSpline();
		
		CurrentSpline.AddPoint(MeshRoots[0].WorldLocation);
		CurrentSpline.AddPoint(MeshRoots[Math::TruncToInt(MeshRoots.Num() / 2.0)].WorldLocation);
		CurrentSpline.AddPoint(MeshRoots[MeshRoots.Num()-1].WorldLocation);

		for(auto Player : Game::Players)
		{
			FVector Loc = CurrentSpline.GetClosestLocationToLocation(Player.ActorLocation);
			if(Player.IsMio())
				ClawAttackCamShakeActorMio.SetActorLocation(Loc);
			else
				ClawAttackCamShakeActorZoe.SetActorLocation(Loc);

			float Dist = Loc.DistSquared2D(Player.ActorLocation, FVector::UpVector);

			if(Dist > Math::Square(2000))
				return;

			float FFStrength = Math::GetMappedRangeValueClamped(FVector2D(0, Math::Square(2000)), FVector2D(1, 0), Dist);
			float LeftFF = FFStrength;
			float RightFF = FFStrength;
			Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
		}
	}

	void ActivateClawAttack(ATundraBoss Boss)
	{
		SetActorLocation(Boss.ActorTransform.TransformPosition(ClawRelativeTransform.Location));
		SetActorRotation(Boss.ActorTransform.TransformRotation(ClawRelativeTransform.Rotation));

		ResetClawPos();
		SetVFXActive(true);
		SetCollisionBoxesEnabled(true);
		SetActorTickEnabled(true);
		ActiveTimer = 0;
		bShouldTickActiveTimer = true;
		UTundraBossClawAttackEffectHandler::Trigger_OnSpawned(this);

		ClawAttackCamShakeActorMio.SetClawAttackCamShakeActive(true);
		ClawAttackCamShakeActorZoe.SetClawAttackCamShakeActive(true);
	}

	void DeactivateClawAttack()
	{
		SetActorTickEnabled(false);
		SetVFXActive(false);
		SetCollisionBoxesEnabled(false);
		ClawAttackCamShakeActorMio.SetClawAttackCamShakeActive(false);
		ClawAttackCamShakeActorZoe.SetClawAttackCamShakeActive(false);
	}

	UFUNCTION()
	private void OnKillBoxOverlap(AHazePlayerCharacter Player)
	{
		FVector Dir;
		for (int i = 0; i < KillBoxes.Num(); ++i)
		{
			if (KillBoxes[i].IsPlayerInTrigger(Player))
				Dir = ComponentDir[i];
		}
		
		FPlayerDeathDamageParams DeathParams;
		DeathParams.ImpactDirection = Dir;
		DeathParams.ForceScale = 10;

		Player.DamagePlayerHealth(0.5, DeathParams, ClawAttackDamageEffect, ClawAttackDeathEffect);

#if TEST
		if(Player.GetGodMode() == EGodMode::God)
			return;
#endif
		
		Player.ApplyKnockdown(Dir * 500, 1, Cooldown = 2);
		UTundraBossClawAttackEffectHandler::Trigger_OnKnockDown(this);
	}

	void SetVFXActive(bool bActive)
	{
		if(bActive)
		{
			for(auto FX : FxComps)
			{
				FX.ReinitializeSystem();
				FX.Activate(true);
			}
		}
		else
		{
			for(auto FX : FxComps)
				FX.DeactivateImmediate();
		}
	}

	void SetCollisionBoxesEnabled(bool bEnabled)
	{
		for(auto Box : KillBoxes)
		{
			if (bEnabled)
				Box.EnableTrigger(this);
			else
				Box.DisableTrigger(this);
		}
	}

	void ResetClawPos()
	{
		for(int i = 0; i < MeshRoots.Num(); i++)
			MeshRoots[i].SetRelativeLocation(StartLocs[i]);
	}

	UFUNCTION(CallInEditor)
	void SetClawAttackRelativeLocation()
	{
		MeshRoots.Empty();

		MeshRoots.Add(Claw01Root);
		MeshRoots.Add(Claw02Root);
		MeshRoots.Add(Claw03Root);
		MeshRoots.Add(Claw04Root);
		MeshRoots.Add(Claw05Root);
		MeshRoots.Add(Claw06Root);
		MeshRoots.Add(Claw07Root);
		MeshRoots.Add(Claw08Root);
		MeshRoots.Add(Claw09Root);
		MeshRoots.Add(Claw10Root);

		float Y_Value = 1200;
		float Y_Subtraction = 0;
		float YawValue = 40.0;
		float YawSubtraction = 0;

		for(auto MeshRoot : MeshRoots)
		{
			MeshRoot.SetRelativeLocation(FVector(0.0, Y_Value - Y_Subtraction, 60.0));
			MeshRoot.SetRelativeRotation(FRotator(0, YawValue - YawSubtraction, 0));
			Y_Subtraction += (Y_Value * 2) / 9.0;
			YawSubtraction += (YawValue * 2) / 9.0;
		}
	}

	UFUNCTION(CallInEditor)
	void SetClawRelativeTransform()
	{
		ClawRelativeTransform = ActorRelativeTransform;
	}
};

class UTundraBossClawAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKnockDown() {}

};