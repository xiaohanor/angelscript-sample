

UCLASS()
class AChaosLaserCutterActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Movable;

#if EDITOR

	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "RuntimeSpline";

#endif

	AEmittingSphereFieldSystemActor FieldSystem;

	UFUNCTION(BlueprintCallable)
	void StartLaser()
	{
		if(FieldSystem == nullptr)
		{
			AActor SpawnedActor = SpawnActor(AEmittingSphereFieldSystemActor);
			FieldSystem = Cast<AEmittingSphereFieldSystemActor>(SpawnedActor);
		}

		check(FieldSystem != nullptr);
	}

	UFUNCTION(BlueprintCallable)
	void EndLaser()
	{
		if(FieldSystem != nullptr && !FieldSystem.IsActorBeingDestroyed())
		{
			FieldSystem.DestroyActor();
			FieldSystem = nullptr;
		}

	}

	UFUNCTION(BlueprintCallable)
	void UpdateLaserFromMio()
	{
		FTransform MioVIEW = Game::Mio.ViewTransform;

		FVector Start = MioVIEW.Location + MioVIEW.Rotation.Vector()*50;
		FVector End = Start + MioVIEW.Rotation.Vector()*3000;

		UpdateLaser(Start, End);
	}

	void UpdateLaser(FVector StartLocation, FVector EndLocation)
	{
		if(FieldSystem == nullptr)
			return;

		FHitResult OutHit;
		LineTraceSingle(StartLocation, EndLocation, OutHit, true);

		if(!OutHit.bBlockingHit)
			return;

		FVector TraceDirection = EndLocation - StartLocation;
		TraceDirection.Normalize();

		FVector EmittingPos = OutHit.ImpactPoint;
		EmittingPos += (TraceDirection * FieldSystem.SphereCollision.ScaledSphereRadius);

		FieldSystem.SetActorLocation(EmittingPos);
	}

	bool LineTraceSingle(FVector Start, FVector End, FHitResult& OutHit, bool bComplexTrace = false)
	{
		// trace result data will be incomplete if we do this
		check(Start != End);

		FHazeTraceSettings TraceProfile = Trace::InitChannel(ETraceTypeQuery::WeaponTraceMio);
		TraceProfile.IgnoreActor(Game::Mio);
		TraceProfile.IgnoreActor(Game::Zoe);
		TraceProfile.SetTraceComplex(bComplexTrace);
		TraceProfile.UseLine();

		OutHit = TraceProfile.QueryTraceSingle(Start, End);

		return OutHit.bBlockingHit;
	}

}
