class USkylineBossFlyingLaserCapability : USkylineBossFlyingPhaseChildCapability
{
	// default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	// default CapabilityTags.Add(SkylineBossTags::SkylineBossFocusBeamAttack);

	// TArray<USkylineBossFocusBeamComponent> FocusBeamComponents;
	// TArray<AActor> ActorsToIgnore;

	// TArray<UNiagaraComponent> Beams;

	// FVector TargetVelocity;
	// FVector PredictedAttackLocation;
	// FVector AttackDirection;
	// FVector StartLocation;
	// FVector EndLocation;

	// float SweepLength = 3500.0;
	// float SweepDuration = 0.5;

	// AActor BeamEndActor;

	// UPROPERTY(EditAnywhere)
	// bool bAlternateBeams = false;
	// int CurrentBeams = 0;

	// float FireDelay = 0.5;
	// bool bBeamActive = false;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	Super::Setup();

	// 	Boss.GetComponentsByClass(FocusBeamComponents);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (DeactiveDuration < 1.0)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {

	// 	USkylineBossEventHandler::Trigger_BeamStart(Boss);

	// 	PrintToScreenScaled("Attack", 0.5, FLinearColor::Green, 4.0);

	// 	//Audio
	// 	auto BeamManager = SkylineBossFocusBeam::GetManager();
	// 	BeamManager.StartNewImpactPool();
	// 	USkylineBossEventHandler::Trigger_ImpactPoolStart(Boss);

	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	for (auto Beam : Beams)
	// 		Beam.Deactivate();
	
	// 	Beams.Reset();

	// 	BeamEndActor.DestroyActor();

	// 	USkylineBossEventHandler::Trigger_BeamStop(Boss);

	// 	bBeamActive = false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	//TargetLocation = Owner.ActorLocation + Owner.ActorForwardVector * 5000 + FVector::DownVector * SkylineBoss::ChaseHeightOffset;

	// 	if (!bBeamActive && ActiveDuration > FireDelay)
	// 	{
	// 		bBeamActive = true;


	// 		for (int i = 0; i < FocusBeamComponents.Num(); i++)
	// 		{
	// 			//FocusBeamComponents[i].TraceTarget = Target;
	// 			FocusBeamComponents[i].bFirstImpact = true;

	// 			for (auto BeamEmitter : FocusBeamComponents[i].BeamEmitters)
	// 			{
	// 				auto Beam = Niagara::SpawnLoopingNiagaraSystemAttached(FocusBeamComponents[i].BeamVFX, FocusBeamComponents[i]);
	// 				Beams.Add(Beam);
	// 			}

	// 			BeamEndActor = SpawnActor(FocusBeamComponents[0].FocusBeamEndClass);
	// 		}
	// 	}

	// 	if (!bBeamActive)
	// 		return;

	// 	for (int i = 0; i < FocusBeamComponents.Num(); i++)
	// 	{
	// 		FVector TargetLocation = FocusBeamComponents[i].WorldLocation + FVector::DownVector * SkylineBoss::ChaseHeightOffset;
	// 		FVector TraceEndLocation = FocusBeamComponents[i].TraceAttack(TargetLocation, FVector::DownVector);

	// 		for (int j = 0; j < FocusBeamComponents[i].BeamEmitters.Num(); j++)
	// 		{
	// 			FVector BeamStartLocation = FocusBeamComponents[i].WorldTransform.TransformPositionNoScale(FocusBeamComponents[i].BeamEmitters[j]);

	// 			Beams[j].SetNiagaraVariableFloat("BeamWidth", 300.0);
	// 			Beams[j].SetNiagaraVariableVec3("BeamStart", BeamStartLocation);
	// 			Beams[j].SetNiagaraVariableVec3("BeamEnd", TraceEndLocation);
	// 		}

	// 		BeamEndActor.ActorLocation = TraceEndLocation;
	// 	}
	// }
};