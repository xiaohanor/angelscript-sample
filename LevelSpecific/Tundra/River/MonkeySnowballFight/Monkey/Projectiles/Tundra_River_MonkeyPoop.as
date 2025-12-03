UCLASS(Abstract)
class ATundra_River_MonkeyPoop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	FHazePlaySlotAnimationParams PlayerHitAnim;

	UPROPERTY()
	UForceFeedbackEffect PlayerHitFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PlayerHitCamShake;

	FTraversalTrajectory LaunchTrajectory;

	AHazePlayerCharacter TargetPlayer;
	float ThrowTime;
	bool bHasBeenThrown = false;
	bool bHomingPoop = false;
	ATundra_River_ThrowPoopMonkey PoopMonkey;

	const float Gravity = 90;
	const float Height = 40;

	void CalculateTrajectory(AHazePlayerCharacter _TargetPlayer)
	{
		TargetPlayer = _TargetPlayer;
		bHasBeenThrown = true;
		ThrowTime = Time::GameTimeSeconds;



		LaunchTrajectory.LaunchLocation = ActorLocation;
		LaunchTrajectory.LandLocation = TargetPlayer.ActorLocation;
		LaunchTrajectory.Gravity = FVector::DownVector * Gravity;
		LaunchTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchTrajectory.LaunchLocation, LaunchTrajectory.LandLocation, Gravity, Height);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bHasBeenThrown)
			return;

		const float Speed = 5;
		SetActorLocation(LaunchTrajectory.GetLocation(Time::GetGameTimeSince(ThrowTime) * Speed));

		if(bHomingPoop)
		{
			LaunchTrajectory.LandLocation = TargetPlayer.ActorLocation;
			LaunchTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchTrajectory.LaunchLocation, LaunchTrajectory.LandLocation, Gravity, Height);
		}

		TArray<EObjectTypeQuery> Queries;

		if(!bHomingPoop)
			Queries.Add(EObjectTypeQuery::WorldStatic);

		Queries.Add(EObjectTypeQuery::PlayerCharacter);
		FHazeTraceSettings SphereTrace = Trace::InitObjectTypes(Queries);
		SphereTrace.UseSphereShape(40);

		auto Overlaps = SphereTrace.QueryOverlaps(ActorLocation);
		for(auto Overlap : Overlaps)
		{
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if(HitPlayer != nullptr)
			{
				FMonkeyPoopEventData Params; //Johannes added for VO
				Params.Player = HitPlayer; //Johannes added for VO

				//Audio
				EffectEvent::LinkActorToReceiveEffectEventsFrom(HitPlayer, this);

				UTundra_River_MonkeyPoopEventHandler::Trigger_OnPoopHit(this, Params); //Johannes added EventData for VO

				if(PoopMonkey != nullptr)
					UTundra_River_PoopMonkeyEventHandler::Trigger_OnPoopHit(PoopMonkey);
				
				// FVector Dir = (HitPlayer.ActorLocation - PoopMonkey.ActorLocation).GetSafeNormal();
				// FStumble Stumble;
				// Stumble.Move = Dir * 250;
				// HitPlayer.ApplyStumble(Stumble);
				HitPlayer.ApplyKnockdown(GetDirectionTo(HitPlayer), 1);
				HitPlayer.PlayForceFeedback(PlayerHitFF, false, false, this);
				HitPlayer.PlayCameraShake(PlayerHitCamShake, this);
			}
			else
			{
				UTundra_River_MonkeyPoopEventHandler::Trigger_OnPoopHitGround(this);

				if(PoopMonkey != nullptr)
					UTundra_River_PoopMonkeyEventHandler::Trigger_OnPoopHitGround(PoopMonkey);
			}
		}

		if(Overlaps.Num() > 0)
			DestroyActor();
	}
};