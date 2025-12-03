// class USkylineBossFocusBeamAttackCapability : USkylineBossChildCapability
// {
// 	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
// 	default CapabilityTags.Add(SkylineBossTags::SkylineBossFocusBeamAttack);

// 	TArray<USkylineBossFocusBeamComponent> FocusBeamComponents;
// 	TArray<AActor> ActorsToIgnore;

// 	AHazeActor Target;
// 	FVector TargetLocation;

// 	TArray<UNiagaraComponent> Beams;

// 	AActor BeamEndActor;

// 	UPROPERTY(EditAnywhere)
// 	bool bAlternateBeams = false;
// 	int CurrentBeams = 0;

// 	float InitialSpeed = 0.0;
// 	float TargetSpeed = 4000.0;
// 	FHazeAcceleratedFloat AcceleratedSpeed;

// 	float FireDelay = 0.5;
// 	bool bBeamActive = false;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		Super::Setup();

// 		Boss.GetComponentsByClass(FocusBeamComponents);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if (DeactiveDuration < 8.0)
// 			return false;

// 		if (Boss.LookAtTarget.Get() == nullptr)
// 			return false;

// 		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if (ActiveDuration > FireDelay + 6.0)
// 			return true;

// //		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
// //			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		Boss.AnimData.bFiringLaser = true;

// 		Target = Boss.LookAtTarget.Get();

// 		USkylineBossEventHandler::Trigger_BeamStart(Boss);
	
// 		PrintToScreenScaled("Attack", 0.5, FLinearColor::Green, 4.0);

// 		//Audio
// 		auto BeamManager = SkylineBossFocusBeam::GetManager();
// 		BeamManager.StartNewImpactPool();
// 		USkylineBossEventHandler::Trigger_ImpactPoolStart(Boss);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		Boss.AnimData.bFiringLaser = false;

// 		for (auto Beam : Beams)
// 			Beam.Deactivate();

// 		Beams.Reset();

// 		BeamEndActor.DestroyActor();

// 		USkylineBossEventHandler::Trigger_BeamStop(Boss);

// 		bBeamActive = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if (!bBeamActive && ActiveDuration > FireDelay)
// 		{
// 			bBeamActive = true;

// 			InitialSpeed = Math::Min(Target.ActorVelocity.Size() * 1.0, TargetSpeed);
// 			AcceleratedSpeed.SnapTo(InitialSpeed, InitialSpeed);

// 			FVector TargetGroundLocation;
// 			FocusBeamComponents[0].GetTargetGroundLocation(Target, TargetGroundLocation);

// 			TargetLocation = TargetGroundLocation + Target.ActorForwardVector * -1000.0; 

// 			for (int i = 0; i < FocusBeamComponents.Num(); i++)
// 			{
// 				FocusBeamComponents[i].TraceTarget = Target;
// 				FocusBeamComponents[i].bFirstImpact = true;

// 				for (auto BeamEmitter : FocusBeamComponents[i].BeamEmitters)
// 				{
// 					auto Beam = Niagara::SpawnLoopingNiagaraSystemAttached(FocusBeamComponents[i].BeamVFX, FocusBeamComponents[i]);
// 					Beams.Add(Beam);
// 				}

// 				BeamEndActor = SpawnActor(FocusBeamComponents[0].FocusBeamEndClass);
// 			}

// 		}

// 		if (!bBeamActive)
// 			return;

// 		FVector TargetGroundLocation;

// 		if (!FocusBeamComponents[0].GetTargetGroundLocation(Target, TargetGroundLocation))
// 			TargetGroundLocation = Target.ActorLocation;

// 		FVector ToTarget = TargetGroundLocation - TargetLocation;

// 		AcceleratedSpeed.AccelerateTo(TargetSpeed, 3.0, DeltaTime);

// 		TargetLocation += ToTarget.SafeNormal * Math::Min(AcceleratedSpeed.Value * DeltaTime, ToTarget.Size());

// 		FVector Direction = (TargetLocation - TargetGroundLocation).SafeNormal;

// 		for (int i = 0; i < FocusBeamComponents.Num(); i++)
// 		{
// 			FVector TraceEndLocation = FocusBeamComponents[i].TraceAttack(TargetLocation, Direction);

// 			for (int j = 0; j < FocusBeamComponents[i].BeamEmitters.Num(); j++)
// 			{
// 				FVector BeamStartLocation = FocusBeamComponents[i].WorldTransform.TransformPositionNoScale(FocusBeamComponents[i].BeamEmitters[j]);

// 				if (j == 0)
// 					BeamStartLocation = Boss.Mesh.GetSocketLocation(n"LeftGunMuzzle");
// 				else
// 					BeamStartLocation = Boss.Mesh.GetSocketLocation(n"RightGunMuzzle");

// 				Beams[j].SetNiagaraVariableFloat("BeamWidth", 300.0);
// 				Beams[j].SetNiagaraVariableVec3("BeamStart", BeamStartLocation);
// 				Beams[j].SetNiagaraVariableVec3("BeamEnd", TraceEndLocation);
// 			}

// 			BeamEndActor.ActorLocation = TraceEndLocation;
// 			BeamEndActor.SetActorRotation()
// 			Boss.AnimData.LaserLocation = TraceEndLocation;
// 		}
// 	}
// }