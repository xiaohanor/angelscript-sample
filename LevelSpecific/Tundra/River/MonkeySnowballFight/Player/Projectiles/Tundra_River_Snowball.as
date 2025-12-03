UCLASS(Abstract)
class ATundra_River_Snowball : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Trail;

	UPROPERTY()
	FHazePlaySlotAnimationParams PlayerHitAnim;

	UPROPERTY()
	UForceFeedbackEffect PlayerHitFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PlayerHitCamShake;

	AHazePlayerCharacter OwningPlayer;

	FTraversalTrajectory LaunchTrajectory;
	bool bHasBeenThrown = false;
	float ThrowTime;

	void CalculateTrajectory(FVector EndLocation)
	{
		bHasBeenThrown = true;
		ThrowTime = Time::GameTimeSeconds;

		const float Gravity = 10;
		const float Height = 20;

		LaunchTrajectory.LaunchLocation = ActorLocation;
		LaunchTrajectory.LandLocation = EndLocation;
		LaunchTrajectory.Gravity = FVector::DownVector * Gravity;
		LaunchTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchTrajectory.LaunchLocation, LaunchTrajectory.LandLocation, Gravity, Height);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bHasBeenThrown)
			return;

		//LaunchTrajectory.DrawDebug(FLinearColor::Green, 0);

		const float Speed = 20;
		SetActorLocation(LaunchTrajectory.GetLocation(Time::GetGameTimeSince(ThrowTime) * Speed));


		TArray<EObjectTypeQuery> Queries;
		Queries.Add(EObjectTypeQuery::WorldStatic);
		Queries.Add(EObjectTypeQuery::PlayerCharacter);
		Queries.Add(EObjectTypeQuery::EnemyCharacter);
		FHazeTraceSettings SphereTrace = Trace::InitObjectTypes(Queries);
		SphereTrace.UseSphereShape(80);

		auto Overlaps = SphereTrace.QueryOverlaps(ActorLocation);
		for(auto Overlap : Overlaps)
		{
			OwningPlayer.PlayForceFeedback(ForceFeedback::Default_Very_Light, this, 1);
			
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if(HitPlayer != nullptr)
			{
				if(HitPlayer == OwningPlayer)
					return;

				FSnowBallEventData Params;
				Params.Player = HitPlayer;
				Params.HitLocation = ActorLocation;
				UTundra_River_SnowballEventHandler::Trigger_OnSnowballHit(this, Params);
				HitPlayer.PlayForceFeedback(PlayerHitFF, false, false, this);
				HitPlayer.PlayCameraShake(PlayerHitCamShake, this);
				HitPlayer.ApplyKnockdown(OwningPlayer.GetDirectionTo(HitPlayer), 1);
				// HitPlayer.AddKnockbackImpulse(this.GetDirectionTo(HitPlayer), 800, 800);
			}
			else
			{
				ATundra_River_ThrowPoopMonkey Monkey = Cast<ATundra_River_ThrowPoopMonkey>(Overlap.Actor);
				if(Monkey != nullptr)
				{
					FSnowBallEventData Params;
					Params.Player = nullptr;
					Params.HitLocation = ActorLocation;
					UTundra_River_SnowballEventHandler::Trigger_OnSnowballHitGeo(this, Params);

					if(HasControl())
						Monkey.CrumbGetHit(this);
					else
						Monkey.GetHit(this);
				}
				else
				{
					FSnowBallEventData Params;
					Params.Player = nullptr;
					Params.HitLocation = ActorLocation;
					UTundra_River_SnowballEventHandler::Trigger_OnSnowballHitGeo(this, Params);
				}
			}
		}

		if(HasControl())
		{
			if(Overlaps.Num() > 0 || Time::GetGameTimeSince(ThrowTime) > 3)
			{
				CrumbHitSomething();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitSomething()
	{
		Trail.Deactivate();
		MeshComp.SetHiddenInGame(true);
		SetActorTickEnabled(false);
		Timer::SetTimer(this, n"DestroySnowball", 0.5);
	}

	UFUNCTION()
	private void DestroySnowball()
	{
		DestroyActor();
	}
};