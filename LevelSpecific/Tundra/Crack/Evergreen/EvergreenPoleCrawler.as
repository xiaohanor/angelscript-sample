event void FOnCrawlerWasKilled();

class AEvergreenPoleCrawler : AKineticSplineFollowActor
{
	default NetworkMode = EKineticSplineFollowNetwork::PredictedSyncPosition;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineRef;

	UPROPERTY()
	UNiagaraSystem DeathFX;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityComp;

	UPROPERTY()
	FOnCrawlerWasKilled TheCrawlerWasKilled;

	UPROPERTY(EditInstanceOnly)
	bool bSetRotationFromVelocity = false;

	UPROPERTY(EditInstanceOnly)
	bool bClimbUpsideDown = false;

	UPROPERTY(EditInstanceOnly)
	bool bIsInEvergreenSide = false;

	UPROPERTY(EditInstanceOnly)
	bool bIsInSpiderCave = false;

	UPROPERTY()
	bool bHasBeenCaught = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		TheCrawlerWasKilled.AddUFunction(this, n"CrawlerWasKilled");
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHasBeenCaught)
			return;
		
		Super::Tick(DeltaSeconds);

		FRotator TargetRot;

		if(bIsInEvergreenSide)
		{
			FVector Velocity = GetRawLastFrameTranslationVelocity();
			FVector Forward = SplineRef.Spline.GetClosestSplineWorldRotationToWorldLocation(ActorLocation).ForwardVector;
			Forward *= Math::Sign(Forward.DotProduct(Velocity));
			TargetRot = FRotator::MakeFromXZ(Forward, FVector::ForwardVector);
		}
		else
		{
			if(bSetRotationFromVelocity)
			{
				TargetRot = GetRawLastFrameTranslationVelocity().Rotation();
			}
			
			if(bClimbUpsideDown)
				TargetRot += FRotator(0, 0, 180);
		}
		
		if(bSetRotationFromVelocity || bClimbUpsideDown)
		{
			FRotator NewRot = Math::RInterpConstantShortestPathTo(SkelMesh.WorldRotation, TargetRot, DeltaSeconds, 600);
			SkelMesh.SetWorldRotation(NewRot);
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetCrawlerRelativeLocation()
	{
		return GetActorRelativeLocation();
	}

	UFUNCTION()
	void CrawlerWasKilled()
	{

	}

	UFUNCTION(BlueprintCallable)
	void KnockBackPlayer(AHazePlayerCharacter Player)
	{
		auto HealthComp = UPlayerHealthComponent::Get(Player);
		if(!HealthComp.CanTakeDamage())
			return;

		if(bIsInSpiderCave)
		{
			Player.ApplyKnockdown((ActorForwardVector * 800) + FVector::UpVector * 200);
			Player.DamagePlayerHealth(0.5);
		}
		else
		{
			Player.ApplyKnockdown((-Player.ActorForwardVector * 1700) + FVector::UpVector * 800);
			Player.DamagePlayerHealth(0.5);
		}
	}

	UFUNCTION(BlueprintCallable)
	void DestroyCrawler()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathFX, ActorLocation);
		TheCrawlerWasKilled.Broadcast();
		DestroyActor();
	}
};