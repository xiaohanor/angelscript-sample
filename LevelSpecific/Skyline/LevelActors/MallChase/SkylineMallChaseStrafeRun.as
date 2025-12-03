class ASkylineMallChaseStrafeRun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TargetRoot;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	FSplinePosition SplinePosition;

	UPROPERTY(EditAnywhere)
	bool bIsActivated = false;

	UPROPERTY(EditAnywhere)
	float StrafeRunInterval = 1.5;
	float StrafeRunTime = 0.0;

	UPROPERTY(EditAnywhere)
	float Speed = 2000.0;

	UPROPERTY(EditAnywhere)
	float Radius = 200.0;

	UPROPERTY(EditAnywhere)
	float ImpactInterval = 0.05;
	float ImpactTime = 0.0;

	UPROPERTY(EditAnywhere)
	float OffsetTimeScale = 0.0;
	float OffsetTime = 0.0;

	UPROPERTY(EditAnywhere)
	float InitialDelay = 0.0;

	UPROPERTY(EditAnywhere)
	int NumOfImpacts = 5;

	UPROPERTY(EditAnywhere, Category = "Audio")
	float MaxPassbyDistance = 1000;
	private float MaxPassbyDistanceSqrd = 0;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BulletTrace;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BulletImpact;

	bool bShouldDeactivate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
			SplinePosition = SplineActor.Spline.GetSplinePositionAtSplineDistance(0.0);	
	
		float StrafeRunDuration = SplinePosition.CurrentSpline.SplineLength / Speed;
		OffsetTime = StrafeRunDuration * OffsetTimeScale;
		InitialDelay = OffsetTime; // Temp override idk

		MaxPassbyDistanceSqrd = Math::Square(MaxPassbyDistance);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated)
			return;

		if (InitialDelay >= 0.0)
		{
			InitialDelay -= DeltaSeconds;
			return;
		}

		if (Time::GameTimeSeconds < StrafeRunTime)
		{
			FVector Direction = (SplinePosition.WorldLocation - ActorLocation).SafeNormal;

			FQuat Rotation = FQuat::Slerp(ActorQuat, Direction.ToOrientationQuat(), 3.0 * DeltaSeconds);

			ActorRotation = Rotation.Rotator();

			if (bShouldDeactivate)
				Deactivate();

			return;
		}

		// Track Players
		for (auto Player : Game::Players)
		{
			if (Player.ActorLocation.Distance(SplinePosition.WorldLocation) < Radius)
				Player.KillPlayer();
		}

		if (!SplinePosition.Move(Speed * DeltaSeconds))
		{
			SplinePosition = SplineActor.Spline.GetSplinePositionAtSplineDistance(0.0);	
			StrafeRunTime = Time::GameTimeSeconds + StrafeRunInterval;

			if (bShouldDeactivate)
				Deactivate();

			return;
		}

		FVector Direction = (SplinePosition.WorldLocation - ActorLocation).SafeNormal;

		FRotator Rotation = Direction.Rotation();

		ActorRotation = Rotation;

		TargetRoot.WorldTransform = SplinePosition.WorldTransform;

		if (Time::GameTimeSeconds > ImpactTime)
		{
			// Effects
			for (int i = 0; i < NumOfImpacts; i++)
			{
				float RandomOffsetSide = Math::RandRange(-Radius, Radius);
				float RandomOffsetDepth = Math::RandRange(-Radius, Radius);

				FVector Offset = SplinePosition.WorldRightVector * RandomOffsetSide + SplinePosition.WorldForwardVector * RandomOffsetDepth;

				FVector Start = ActorLocation;
				FVector End = SplinePosition.WorldLocation + Offset;

				FVector TraceVector = End - Start;

				auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);	
				Trace.IgnoreActor(AttachParentActor);

				End = Start + TraceVector.SafeNormal * (TraceVector.Size() + 100.0);
				auto HitResult = Trace.QueryTraceSingle(Start, End);
//
//				Debug::DrawDebugLine(Start, End, FLinearColor::Green, 5.0, 0.0);
				FVector HitLocation = HitResult.TraceEnd;
				if (HitResult.bBlockingHit)
				{
//					Debug::DrawDebugPoint(HitResult.Location, 30.0, FLinearColor::Green, 1.0);

					HitLocation = HitResult.ImpactPoint;
					Niagara::SpawnOneShotNiagaraSystemAtLocation(BulletImpact, HitResult.ImpactPoint, TraceVector.Rotation() + FRotator(-90.0, 0.0, 0.0));


					FSkylineMallChaseStrafeRunWeaponParams WeaponParams;
					WeaponParams.MagazinSize = 1;
					WeaponParams.ShotsFiredAmount = 1;
					UASkylineMallChaseStrafeRunProjectileEffectEventHandler::Trigger_OnShotFired(this, WeaponParams);

					FSkylineMallChaseStrafeRunProjectileImpactParams Params;
					Params.ImpactLocation = HitResult.ImpactPoint;
					Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(HitResult, FHazeTraceSettings()).AudioAsset);
					Params.ImpactNormal = AudioSharedProjectiles::GetProjectileImpactAngle(ActorForwardVector, HitResult.ImpactNormal);
					UASkylineMallChaseStrafeRunProjectileEffectEventHandler::Trigger_Impact(this, Params);
				}

//				Debug::DrawDebugPoint(ActorLocation, 25.f, FLinearColor::Yellow, bDrawInForeground = true);

				auto NiagaraComponent = Niagara::SpawnOneShotNiagaraSystemAtLocation(BulletTrace, ActorLocation, ActorRotation);
				NiagaraComponent.SetNiagaraVariableVec3("Start", ActorLocation);
				NiagaraComponent.SetNiagaraVariableVec3("End", HitLocation);
				NiagaraComponent.SetNiagaraVariableFloat("Time", HitResult.Time * 0.3);
				NiagaraComponent.SetNiagaraVariableFloat("BeamWidth", 2.0);
				
				for(auto Player : Game::GetPlayers())
				{
					FVector ProjectedPassbyLocation = Math::ClosestPointOnLine(Start, End, Player.ActorLocation);
					const float PassbyDistSqrd = ProjectedPassbyLocation.DistSquared(Player.ActorLocation);
					if(PassbyDistSqrd <= MaxPassbyDistanceSqrd)
					{
						const FVector ShotDir = (End - Start).GetSafeNormal();
						const FVector PlayerCameraForward = Player.ControlRotation.ForwardVector;
						const float NormalizedDirectionValue = PlayerCameraForward.DotProduct(ShotDir) * -1;

						FWeaponProjectileFlybyHitScanParams Params;
						Params.TargetPlayer = Player;
						Params.Distance = ProjectedPassbyLocation.Distance(Player.ActorLocation) / MaxPassbyDistance;
						Params.NormalizedDirection = NormalizedDirectionValue;

						UHitscanProjectileEffectEventHandler::Trigger_HitscanProjectilePassby(this, Params);
					}
				}
			}

			ImpactTime = Time::GameTimeSeconds + ImpactInterval;
		}
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		SetActorTickEnabled(false);
		AddActorDisable(this);
	}

	UFUNCTION()
	void FinishRunAndDeactivate()
	{
		bShouldDeactivate = true;
	}		

	UFUNCTION(BlueprintPure)
	float GetSplinePositionDistanceToPlayer(const AHazePlayerCharacter Player)
	{
		return SplinePosition.GetWorldLocation().Distance(Player.ActorLocation);
	}
}

struct FSkylineMallChaseStrafeRunProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat;

	UPROPERTY()
	float ImpactNormal;
}

struct FSkylineMallChaseStrafeRunWeaponParams
{
	UPROPERTY()
    int ShotsFiredAmount = 0;

    UPROPERTY()
    int MagazinSize = 0;
}

UCLASS(Abstract)
class UASkylineMallChaseStrafeRunProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Impact(FSkylineMallChaseStrafeRunProjectileImpactParams Params) {}

	UFUNCTION(BlueprintEvent)
	void OnShotFired(FSkylineMallChaseStrafeRunWeaponParams WeaponParams) {}
};