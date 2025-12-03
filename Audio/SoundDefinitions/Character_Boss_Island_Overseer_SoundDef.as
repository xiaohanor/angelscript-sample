
UCLASS(Abstract)
class UCharacter_Boss_Island_Overseer_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaserBombAttackStop(FIslandOverseerLaserAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnLaserBombAttackStart(FIslandOverseerLaserAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnRecloseTakeDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnAdvanceStart(){}

	UFUNCTION(BlueprintEvent)
	void OnTremorImpact(FIslandOverseerEventHandlerOnTremorImpactData Data){}

	UFUNCTION(BlueprintEvent)
	void OnCrushableHit(){}

	UFUNCTION(BlueprintEvent)
	void OnBeamActivationHit(){}

	UFUNCTION(BlueprintEvent)
	void OnFloodPlatformPull(){}

	UFUNCTION(BlueprintEvent)
	void OnPeekAttackEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnPeekAttackLaunch(FIslandOverseerEventHandlerOnPeekAttackLaunchData Data){}

	UFUNCTION(BlueprintEvent)
	void OnPeekAttackStart(FIslandOverseerEventHandlerOnPeekAttackStartData Data){}

	UFUNCTION(BlueprintEvent)
	void OnPeekEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnPeekStart(){}

	UFUNCTION(BlueprintEvent)
	void OnHeadTakeDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnRedBlueHit(FIslandOverseerEventHandlerOnRedBlueHitData Data){}

	UFUNCTION(BlueprintEvent)
	void OnBallAttackTelegraphStop(){}

	UFUNCTION(BlueprintEvent)
	void OnSwipeTelegraphStop(FIslandOverseerSwipeAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnSwipeTelegraphStart(FIslandOverseerSwipeAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnDoorShakeAttackSpawn(){}

	UFUNCTION(BlueprintEvent)
	void OnDoorShakeAttackTelegraphStop(){}

	UFUNCTION(BlueprintEvent)
	void OnDoorShakeAttackTelegraphStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSmashAttackFloorHit(){}

	UFUNCTION(BlueprintEvent)
	void OnFloodAttackStart(){}

	UFUNCTION(BlueprintEvent)
	void OnFloodAttackStop(){}

	UFUNCTION(BlueprintEvent)
	void OnPeekBombImpact(FIslandOverseerPeekBombOnHitEventData Params){}

	UFUNCTION(BlueprintEvent)
	void OnDoorShakeAttackImpact(FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data){}

	UFUNCTION(BlueprintEvent)
	void OnDoorShakeDebrisImpact(FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data){}

	UFUNCTION(BlueprintEvent)
	void OnLeftEyeExplode(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter HeadEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter LeftHandEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter RightHandEmitter;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter FloodEmitter;

	AAIIslandOverseer Overseer;

	private float CachedLeftArmMovementSpeed = 0.0;
	private float CachedRightArmMovementSpeed = 0.0;

	private float MAX_ARM_MOVEMENT_SPEED = 1200.0;

	private FVector CachedOverseerLocation;
	private FVector CachedLeftHandLocation;
	private FVector CachedRightHandLocation;

	private bool bHasAttachedFloodEmitter = false;

	FVector GetLeftHandLocation() const property
	{
		return LeftHandEmitter.GetEmitterLocation();
	}

	FVector GetRightHandLocation() const property
	{
		return RightHandEmitter.GetEmitterLocation();
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Overseer = Cast<AAIIslandOverseer>(HazeOwner);
	}

	private void AttachFloodEmitter()
	{
		if(bHasAttachedFloodEmitter)
		 	return;

		AIslandOverseerFlood Flood = TListedActors<AIslandOverseerFlood>().GetSingle();
		if(Flood == nullptr)
			return;

		// Grab the first staticmeshcomp, should be the water since the lifts are children under scenecomponents
		UStaticMeshComponent FloodMeshComp = Flood.GetComponentByClass(UStaticMeshComponent);
		FloodEmitter.AudioComponent.AttachTo(FloodMeshComp);
	
		// TODO: I don't know? Good enough...
		float FloodMiddleX = FloodMeshComp.BoundsExtent.X / 8;
		FloodEmitter.AudioComponent.SetRelativeLocation(FVector(0.0, 0.0, FloodMiddleX));
		bHasAttachedFloodEmitter = true;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;

		if(EmitterName == n"FloodEmitter")
		{
			bUseAttach = false;
			return false;
		}

		bUseAttach = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		AttachFloodEmitter();

		for(auto Emitter : Emitters)
		{
			Emitter.SetScreenRelativePostionPanning();
		}

		const FVector OverseerLocation = Overseer.ActorLocation;
		const FVector OverseerVelo = OverseerLocation - CachedOverseerLocation;

		CachedLeftArmMovementSpeed = (((LeftHandLocation - CachedLeftHandLocation) - OverseerVelo).Size() / DeltaSeconds) / MAX_ARM_MOVEMENT_SPEED;
		CachedRightArmMovementSpeed = (((RightHandLocation - CachedRightHandLocation) - OverseerVelo).Size() / DeltaSeconds) / MAX_ARM_MOVEMENT_SPEED;

		CachedOverseerLocation = OverseerLocation;
		CachedLeftHandLocation = LeftHandLocation;
		CachedRightHandLocation = RightHandLocation;
	}

	UFUNCTION(BlueprintPure)
	void GetArmMovementSpeeds(float&out Left, float&out Right, float&out Combined)
	{
		Left = CachedLeftArmMovementSpeed;
		Right = CachedRightArmMovementSpeed;
		Combined = (CachedLeftArmMovementSpeed + CachedRightArmMovementSpeed) / 2;
	}
}