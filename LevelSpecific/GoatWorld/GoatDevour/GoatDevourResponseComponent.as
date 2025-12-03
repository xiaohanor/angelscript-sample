event void FGoatDevourEvent();
event void FGoatDevourReachMouthEvent();
event void FGoatDevourSpitEvent(FGoatDevourSpitParams Params);

class UGoatDevourResponseComponent : UActorComponent
{
	UPROPERTY()
	FGoatDevourEvent OnDevoured;

	UPROPERTY()
	FGoatDevourReachMouthEvent OnReachedMouth;

	UPROPERTY()
	FGoatDevourSpitEvent OnSpit;

	UPROPERTY(EditAnywhere)
	bool bDestroyOnDevour = false;

	UPROPERTY(EditAnywhere)
	bool bDisableOnDevour = false;

	UPROPERTY(EditAnywhere)
	float DisableDuration = 4.0;

	UPROPERTY(EditAnywhere)
	bool bScaleActor = true;
	FVector StartScale;

	UPROPERTY(EditAnywhere)
	float ScaleDownSpeedMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float ScaleUpSpeedMultiplier = 1.0;

	bool bTravellingToMouth = false;
	bool bDevoured = false;
	AGoatDevourGoatActor TargetGoat;

	bool bSpitOut = false;

	FTransform OriginalTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalTransform = Owner.ActorTransform;
	}

	void GetDevoured(AGoatDevourGoatActor Goat)
	{
		StartScale = Owner.ActorScale3D;

		bSpitOut = false;
		Owner.SetActorEnableCollision(false);

		TargetGoat = Goat;
		bTravellingToMouth = true;

		OnDevoured.Broadcast();
	}

	void SpitOut(FGoatDevourSpitParams Params)
	{
		bSpitOut = true;
		bDevoured = false;
		OnSpit.Broadcast(Params);
		Owner.SetActorHiddenInGame(false);
		Owner.SetActorEnableCollision(true);

		if (Params.ResponseComp != nullptr)
			Params.ResponseComp.OnLaunch.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bTravellingToMouth)
		{
			FVector TargetLoc = TargetGoat.MouthComp.WorldLocation;
			FVector CurrentLoc = Math::VInterpConstantTo(Owner.ActorLocation, TargetLoc, DeltaTime, 2000.0);
			Owner.SetActorLocation(CurrentLoc);
			Owner.AddActorWorldRotation(FRotator(600.0 * DeltaTime, 400.0 * DeltaTime, 900.0 * DeltaTime));

			if (bScaleActor)
			{
				FVector Scale = Math::VInterpConstantTo(Owner.ActorScale3D, FVector(0.0), DeltaTime, 5.0 * ScaleDownSpeedMultiplier);
				Owner.SetActorScale3D(FVector(Scale));
			}
			
			if (TargetLoc.Equals(CurrentLoc, 20.0))
			{
				bDevoured = true;
				bTravellingToMouth = false;
				Owner.SetActorHiddenInGame(true);

				if (bScaleActor)
					Owner.SetActorScale3D(FVector::ZeroVector);

				OnReachedMouth.Broadcast();

				if (bDestroyOnDevour)
					Owner.DestroyActor();

				if (bDisableOnDevour)
					DisableOwner();
			}
		}

		if (bSpitOut)
		{
			if (bScaleActor)
			{
				if (bScaleActor)
				{
					FVector Scale = Math::VInterpConstantTo(Owner.ActorScale3D, StartScale, DeltaTime, 5.0 * ScaleUpSpeedMultiplier);
					Owner.SetActorScale3D(FVector(Scale));
				}
			}
		}
	}

	bool CanBeDevoured()
	{
		if (bTravellingToMouth)
			return false;

		if (bDevoured)
			return false;

		return true;
	}

	void DisableOwner()
	{
		Owner.AddActorDisable(this);
		Timer::SetTimer(this, n"EnableOwner", DisableDuration);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableOwner()
	{
		Owner.SetActorTransform(OriginalTransform);
		Owner.RemoveActorDisable(this);
		Owner.SetActorHiddenInGame(false);
		Owner.SetActorEnableCollision(true);

		bDevoured = false;
		bTravellingToMouth = false;
	}
}

struct FGoatDevourSpitParams
{
	UPROPERTY()
	FVector Direction;

	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	UGoatDevourPlacementComponent PlacementComp = nullptr;

	UPROPERTY()
	UGoatDevourSpitImpactResponseComponent ResponseComp = nullptr;
}