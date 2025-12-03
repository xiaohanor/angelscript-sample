enum EWeeperSpikeTrapState
{
	Inactive,
	WaitingToActivate,
	SpikesRising,
	Active,
	SpikesRetract
}

class ASanctuaryWeeperSpikeTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent Collision;

	UPROPERTY(EditAnywhere)
	ASanctuaryLightOrb Orb;


	
	UPROPERTY(EditAnywhere)
	float DelayTime = 0;

	UPROPERTY(EditAnywhere)
	float ActiveDuration = 0.25;


	EWeeperSpikeTrapState State;

	float RiseSpeed = 600;
	float RiseHeight = 150;

	bool bHasBeenActivated;
	bool bIsActive;
	float TimeToChangeState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Orb.OnActivated.AddUFunction(this, n"OnActivated");
		Orb.OnDeactivated.AddUFunction(this, n"OnDeactivated");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(State == EWeeperSpikeTrapState::Inactive)
		{
			return;
		}
		else if(State == EWeeperSpikeTrapState::WaitingToActivate)
		{
			if(TimeToChangeState <= Time::GameTimeSeconds)
				State = EWeeperSpikeTrapState::SpikesRising;
			
			return;
		}
		else if(State == EWeeperSpikeTrapState::SpikesRising)
		{
			FVector TargetHeight = FVector(0, 0, RiseHeight);
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetHeight, DeltaSeconds, RiseSpeed);

			if(MeshRoot.RelativeLocation.Z >= TargetHeight.Z)
			{
				State = EWeeperSpikeTrapState::Active;
				TimeToChangeState = Time::GameTimeSeconds + ActiveDuration;
			}

		}
		else if(State == EWeeperSpikeTrapState::Active)
		{
			if(TimeToChangeState <= Time::GameTimeSeconds)
				State = EWeeperSpikeTrapState::SpikesRetract;

		}
		else if(State == EWeeperSpikeTrapState::SpikesRetract)
		{
			FVector TargetHeight = FVector(0);
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetHeight, DeltaSeconds, RiseSpeed);

			if(MeshRoot.RelativeLocation.Z <= TargetHeight.Z)
			{
				State = EWeeperSpikeTrapState::Inactive;
			}
			
		}


		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseBoxShape(Collision);
		TraceSettings.IgnoreActor(this);

		auto HitResultArray = TraceSettings.QueryTraceMulti(Collision.WorldLocation, Collision.WorldLocation + Collision.ForwardVector);

		for(FHitResult Hit : HitResultArray)
		{
			if(Hit.bBlockingHit)
			{

				if(Hit.Actor == Game::Zoe)
				{
					Game::Zoe.KillPlayer();
					return;
				}
				
				auto Weeper = Cast<AAISanctuaryWeeper2D>(Hit.Actor);

				if(Weeper != nullptr)
					Weeper.HealthComp.TakeDamage(Weeper.HealthComp.MaxHealth, EDamageType::MeleeSharp, this);
					
				
			}
		}
		
	}

	UFUNCTION()
	private void OnActivated()
	{
		if(State == EWeeperSpikeTrapState::Inactive)
		{
			State = EWeeperSpikeTrapState::WaitingToActivate;
			TimeToChangeState = Time::GameTimeSeconds + DelayTime;
		}
	}

	UFUNCTION()
	private void OnDeactivated()
	{

	}


};