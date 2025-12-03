UCLASS(Abstract)
class USkylineBossFocusBeamComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	private TSubclassOf<ASkylineBossFocusBeamHit> FocusBeamHitClass;

	UPROPERTY(EditDefaultsOnly)
	private UNiagaraSystem BeamVFX;

	const int BeamCount = 2;
	const float BeamLength = 100000.0;
	const float ImpactSpacing = 400.0;

	private ASkylineBoss Boss;

	private bool bAreBeamsActive = false;
	private AHazeActor TraceTarget;
	private TArray<UNiagaraComponent> Beams;

	private bool bFirstImpact = true;
	private FVector LastImpactLocation;
	FVector CurrentImpactLocation;

	private ASkylineBossFocusBeamHit CurrentBeamHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	bool IsBeamActive() const
	{
		return bAreBeamsActive;
	}

	void ActivateBeams(AHazeActor Target)
	{
		if(!ensure(!bAreBeamsActive))
			return;

		TraceTarget = Target;
		bFirstImpact = true;

		for (int i = 0; i < BeamCount; i++)
		{
			// Create a beam niagara for each emitter
			auto Beam = Niagara::SpawnLoopingNiagaraSystemAttached(BeamVFX, this);
			Beams.Add(Beam);
			Beam.Activate(true);
		}

		bAreBeamsActive = true;
	}

	void DeactivateBeams()
	{
		if(!ensure(bAreBeamsActive))
			return;

		for(UNiagaraComponent Beam : Beams)
		{
			Beam.Deactivate();
			Beam.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		Beams.Reset();

		if(IsBeamHitActive())
			DeactivateBeamHit();

		bAreBeamsActive = false;
	}

	FHitResult TraceAttack(FVector TargetLocation, bool&out bOutWasFirstImpact)
	{
		bOutWasFirstImpact = bFirstImpact;

		FHitResult HitResult = TraceForImpact(TargetLocation);

		if (!HitResult.IsValidBlockingHit())
		{
			bFirstImpact = true;
			return HitResult;
		}

		if (bFirstImpact)
		{
			LastImpactLocation = HitResult.ImpactPoint;
			bOutWasFirstImpact = true;
		}
		else
		{
			CurrentImpactLocation = HitResult.ImpactPoint;

			FVector LastToNewImpact = CurrentImpactLocation - LastImpactLocation;

			float StepLength = LastToNewImpact.Size();
			int SubSteps = Math::FloorToInt(StepLength / ImpactSpacing);
			SubSteps = Math::Min(32, SubSteps);

			if (SubSteps > 0)
			{
				float SubStepLength = ImpactSpacing;

				for (int i = 1; i < SubSteps; i++)
				{
					FVector SubStepTarget = LastImpactLocation + LastToNewImpact.SafeNormal * SubStepLength;

					auto SubHitResult = TraceForImpact(SubStepTarget);

					if (SubHitResult.bBlockingHit)
					{
						if ((LastImpactLocation - SubHitResult.ImpactPoint).Size() < SubStepLength * 0.5)
						{
							LastImpactLocation = SubHitResult.ImpactPoint;
							continue;
						}

						LastImpactLocation = SubHitResult.ImpactPoint;
					}
					else
					{
						LastImpactLocation = SubStepTarget;
					}

					LastToNewImpact = CurrentImpactLocation - LastImpactLocation;
				}
			}
		}
	
		return HitResult;
	}

	void UpdateBeams(FHitResult Hit)
	{
		const FVector BeamEndLocation = Hit.IsValidBlockingHit() ? Hit.ImpactPoint : Hit.TraceEnd;

		for (int i = 0; i < BeamCount; i++)
		{
			FVector BeamStartLocation;

			if (i == 0)
				BeamStartLocation = Boss.Mesh.GetSocketLocation(n"LeftGunMuzzle");
			else
				BeamStartLocation = Boss.Mesh.GetSocketLocation(n"RightGunMuzzle");

			Beams[i].SetNiagaraVariableFloat("BeamWidth", 300.0);
			Beams[i].SetNiagaraVariableVec3("BeamStart", BeamStartLocation);
			Beams[i].SetNiagaraVariableVec3("BeamEnd", BeamEndLocation);

			//Debug::DrawDebugLine(BeamStartLocation, BeamEndLocation, FLinearColor::Red, 10);
		}
	}

	void UpdateBeamHit(FHitResult Hit, bool bWasFirstImpact)
	{
		if(Hit.IsValidBlockingHit())
		{
			if(!IsBeamHitActive())
				SpawnBeamHit(Hit.ImpactPoint, Hit.ImpactNormal);

			const FVector Location = Hit.ImpactPoint;
			const FRotator Rotation = FRotator::MakeFromZ(Hit.ImpactNormal);
			CurrentBeamHit.SetActorLocationAndRotation(Location, Rotation);

			CurrentBeamHit.AddImpactPoint();
		}
		else
		{
			if(IsBeamHitActive())
				DeactivateBeamHit();
		}
	}

	bool IsBeamHitActive() const
	{
		return IsValid(CurrentBeamHit);
	}

	private void SpawnBeamHit(FVector Location, FVector Normal)
	{
		if(!ensure(!IsBeamHitActive()))
			return;

		CurrentBeamHit = SpawnActor(FocusBeamHitClass, Location, FRotator::MakeFromZ(Normal));
	}

	private void DeactivateBeamHit()
	{
		if(!ensure(IsBeamHitActive()))
			return;

		CurrentBeamHit.Deactivate();
		CurrentBeamHit = nullptr;
	}

	private void SubTrace(FVector StartTarget, FVector EndTarget) const
	{
		FVector StartLocation = StartTarget;
		FVector EndLocation = EndTarget;

		Debug::DrawDebugPoint(StartLocation, 50.0, FLinearColor::Red, 0.0);
		Debug::DrawDebugPoint(EndLocation, 50.0, FLinearColor::Blue, 0.0);

		FVector StartToEnd = EndLocation - StartLocation;

		float StepLength = StartToEnd.Size();
		int SubSteps = Math::FloorToInt(StepLength / ImpactSpacing);

		if (SubSteps > 0)
		{
			float SubStepLength = ImpactSpacing;

			for (int i = 1; i < SubSteps; i++)
			{
				EndLocation = StartLocation + StartToEnd.SafeNormal * SubStepLength;

				auto HitResult = TraceForImpact(EndLocation);

				if (HitResult.bBlockingHit)
				{
					EndLocation = HitResult.ImpactPoint;

					SubTrace(StartLocation, EndLocation);

					StartToEnd = EndLocation - StartLocation;

					StartLocation = EndLocation;
				}
			}
		}	
	}

	private FHitResult TraceForImpact(FVector TargetLocation) const
	{
		FVector Direction = (TargetLocation - WorldLocation).SafeNormal;

		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(TraceTarget);
		Trace.IgnorePlayers();

		FVector TraceStart = WorldLocation;
		FVector TraceEnd = TraceStart + Direction * BeamLength;

		return Trace.QueryTraceSingle(TraceStart, TraceEnd);			
	}

	bool GetTargetGroundLocation(AHazeActor Target, FVector& OutLocation)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.IgnoreActor(Target);
		Trace.IgnorePlayers();

		FVector TraceStart = Target.ActorLocation + Target.MovementWorldUp * 100.0;
		FVector TraceEnd = TraceStart + Target.MovementWorldUp * -5000.0;

		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		if (HitResult.bBlockingHit)
		{
			OutLocation = HitResult.ImpactPoint;
			return true;
		}

		return false;
	}
};

#if EDITOR
class USkylineBossFocusBeamComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossFocusBeamComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto FocusBeamComp = Cast<USkylineBossFocusBeamComponent>(InComponent);
		if(FocusBeamComp == nullptr)
			return;
		
	}
};
#endif