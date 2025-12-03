	class ASanctuaryBossArenaHydraTarget : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossArenaFloatingPlatform FloatingPlatform;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossArenaCrunchPlatformPlayerTrigger BecomeCruncyWhenPlayerEntersVolume;

	UPROPERTY(EditInstanceOnly)
	ESanctuaryArenaSideOctant HalfHydraTargeting;

	bool bTargetable = true;
	bool bProjectileTargeted = false;
	bool bCruncyTarget = false;
	bool bCruncyTargeted = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (AttachParentActor != nullptr)
		{
			auto Spline = UHazeSplineComponent::Get(AttachParentActor);
			if (Spline != nullptr)
			{
				FTransform TransformOnSpline = Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);

				TransformOnSpline.Location = FVector(TransformOnSpline.Location.X, TransformOnSpline.Location.Y, ActorLocation.Z);
				SetActorLocationAndRotation(
					TransformOnSpline.Location,
					TransformOnSpline.Rotation
				);
			}

			FloatingPlatform = Cast<ASanctuaryBossArenaFloatingPlatform>(AttachParentActor);

			if (FloatingPlatform != nullptr)
			{
				auto GroundTrace = Trace::InitProfile(n"PlayerCharacter");

				FHitResult Hit = GroundTrace.QueryTraceSingle(
					ActorLocation + FVector::UpVector * 150.0,
					ActorLocation - FVector::UpVector * 150.0,
				);

				if (Hit.bBlockingHit && !Hit.bStartPenetrating)
					TargetComp.SetWorldLocation(FVector(TargetComp.WorldLocation.X, TargetComp.WorldLocation.Y, Hit.Location.Z));

				else
					TargetComp.SetRelativeLocation(FVector::ZeroVector);
			}

			SetActorRelativeRotation(FRotator::ZeroRotator);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (BecomeCruncyWhenPlayerEntersVolume != nullptr)
			BecomeCruncyWhenPlayerEntersVolume.OnActorBeginOverlap.AddUFunction(this, n"PlayerEnterVolume");
	}

	UFUNCTION()
	private void PlayerEnterVolume(AActor OverlappedActor, AActor OtherActor)
	{
		if (bTargetable)
			bCruncyTarget = true;
	}
};