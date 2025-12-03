class UBattlefieldLaserComponent : UBattlefieldAttackComponent
{
	UPROPERTY(EditAnywhere)
	float Width = 450.0;

	FVector LaserEndLoc;

	AHazeActor HazeOwner;

	bool bLaserActive;
	
	bool bLaserFollowTargetActive;
	AActor FollowTarget; 
	float FollowTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaserActive)
			return;
		

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Owner);
		
		FHitResult Hit = TraceSettings.QueryTraceSingle(WorldLocation, LaserEndLoc);

		if (Hit.bBlockingHit)
		{
			UBattlefieldLaserResponseComponent ResponseComp = UBattlefieldLaserResponseComponent::Get(Hit.Actor);
			
			if (ResponseComp != nullptr)
			{
				ResponseComp.ApplyImpact();
			}
		}

		if (bLaserFollowTargetActive)
		{
			if (Time::GameTimeSeconds > FollowTime)
			{
				bLaserFollowTargetActive = false;
				DeactivateLaser();
			}

			if (FollowTarget != nullptr)
			{
				SetLaserEndPosition(FollowTarget.ActorLocation);
			}
		}
	}

	UFUNCTION()
	void SetLaserEndPosition(FVector EndLoc)
	{
		FBattlefieldLaserUpdateParams Params;
		Params.EndLocation = EndLoc;
		UBattlefieldLaserEffectHandler::Trigger_UpdateLaserPoint(HazeOwner, Params);
		LaserEndLoc = EndLoc;

		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void SetLaserTargetWithTimer(AActor Target, float FireTime)
	{
		bLaserActive = true;
		bLaserFollowTargetActive = true;
		FollowTarget = Target;
		FollowTime = Time::GameTimeSeconds + FireTime;
		ActivateLaser(FollowTarget.ActorLocation);
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void ActivateLaser(FVector EndLoc)
	{
		bLaserActive = true;
		FBattlefieldLaserStartedParams Params;
		Params.AttachComp = this;
		Params.EndLocation = EndLoc;
		Params.BeamWidth = Width;
		UBattlefieldLaserEffectHandler::Trigger_OnLaserStarted(HazeOwner, Params);
		LaserEndLoc = EndLoc;
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		bLaserActive = false;
		UBattlefieldLaserEffectHandler::Trigger_OnLaserEnd(HazeOwner);
		SetComponentTickEnabled(false);
	}
} 