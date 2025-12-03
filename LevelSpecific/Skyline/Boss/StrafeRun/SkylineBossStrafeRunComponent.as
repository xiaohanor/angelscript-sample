class USkylineBossStrafeRunComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike Animation;
	default Animation.Duration = 2.0;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	float SweepAngle = 20.0;

	AHazeActor AttackTarget;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossStrafeRun> StrafeRunClass;
	ASkylineBossStrafeRun StrafeRun;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BeamVFX;
	UNiagaraComponent Beam;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Animation.BindUpdate(this, n"AnimationUpdate");
		Animation.BindFinished(this, n"AnimationFinished");		
	}

	void BeginStrafeRun(AHazeActor Target)
	{
		AttackTarget = Target;
		StrafeRun = SpawnActor(StrafeRunClass);
		Beam = Niagara::SpawnLoopingNiagaraSystemAttached(BeamVFX, this);
		Animation.Play();
	}

	void AbortStrafeRun()
	{
		StrafeRun.DestroyActor();
		Animation.Stop();
		Animation.NewTime = 0.0;
		Beam.DestroyComponent(this);
	}

	UFUNCTION()
	void AnimationUpdate(float Value)
	{
		float Angle = Math::Lerp(-SweepAngle * 0.5, SweepAngle * 0.5, Value);
		RelativeRotation = FRotator(Angle, 0.0, 0.0);
	
		TraceAttack(AttackTarget);
	}

	UFUNCTION()
	void AnimationFinished()
	{
	}

	void TraceAttack(AHazeActor Target)
	{
		FVector ToTarget = Owner.ActorLocation - Target.ActorLocation;

		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(StrafeRun);

		auto HitResult = Trace.QueryTraceSingle(WorldLocation, WorldLocation + ForwardVector * 500000.0);

		FVector EndLocation = HitResult.TraceEnd;
		if (HitResult.bBlockingHit)
			EndLocation = HitResult.ImpactPoint;

//		Debug::DrawDebugLine(HitResult.TraceStart, EndLocation, FLinearColor::Yellow, 200.0, 0.0);

		Beam.SetNiagaraVariableVec3("BeamStart", WorldLocation);
		Beam.SetNiagaraVariableVec3("BeamEnd", EndLocation);

		if (HitResult.bBlockingHit)
		{
			StrafeRun.SetActorLocationAndRotation(HitResult.ImpactPoint, HitResult.Normal.Rotation());
		}
	}
}