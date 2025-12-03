enum ETundraPoopMonkeyState
{
	Idling,
	PlayerDetected,
	Throwing,
	Hit
}

UCLASS(Abstract)
class ATundra_River_ThrowPoopMonkey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_River_ThrowPoopMonkey_DetectionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_River_ThrowPoopMonkey_GetHitCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"Tundra_River_ThrowPoopMonkey_ThrowPoopCapability");

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ATundra_River_MonkeyPoop> PoopClass;

	UPROPERTY(DefaultComponent)
	UTundra_River_SnowballAutoAimTargetComponent SnowballAutoAimComp;

	FTraversalTrajectory FallTrajectory;

	ETundraPoopMonkeyState State = ETundraPoopMonkeyState::Idling;

	UPROPERTY(EditAnywhere)
	const float DetectionRange = 3000;

	UPROPERTY(EditAnywhere)
	const float ThrowingRange = 2500;

	float TurnSpeed = 100;

	float ThrowPoopDuration = 5.4;

	float NextThrowTime = 0;

	float HitBySnowballTime = -100;

	AHazePlayerCharacter ClosestPlayerInRange;
	float ClosestDistSqrToPlayer;
	AHazePlayerCharacter TargetPlayer;

	bool bFirstPoopThrown = false;
	ATundra_River_MonkeyPoop Poop;


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ClosestPlayerInRange = nullptr;

		AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(ActorLocation);
		ClosestDistSqrToPlayer = ClosestPlayer.GetSquaredDistanceTo(this);
		if (ClosestDistSqrToPlayer <= DetectionRange * DetectionRange)
		{
			float Dot = (ClosestPlayer.ActorLocation - this.ActorLocation).GetSafeNormal().DotProduct(this.ActorForwardVector);
			if (Dot > 0)
			{
				ClosestPlayerInRange = ClosestPlayer;
			}
			else
			{
				// Player is behind the monkeys
				ClosestPlayer = ClosestPlayer.OtherPlayer;
				ClosestDistSqrToPlayer = ClosestPlayer.GetSquaredDistanceTo(this);
				if (ClosestDistSqrToPlayer <= DetectionRange * DetectionRange)
				{
					Dot = (ClosestPlayer.ActorLocation - this.ActorLocation).GetSafeNormal().DotProduct(this.ActorForwardVector);
					if (Dot > 0)
						ClosestPlayerInRange = ClosestPlayer;
				}
			}
		}
	}

	void SpawnPoop()
	{
		Poop = Cast<ATundra_River_MonkeyPoop>(SpawnActor(PoopClass));
		Poop.AttachToComponent(MeshComp, n"RightAttach", EAttachmentRule::SnapToTarget);
		Poop.PoopMonkey = this;
	}

	void ThrowPoop()
	{
		if (Poop == nullptr)
			return;

		Poop.DetachFromActor();
		check(TargetPlayer != nullptr);
		Poop.CalculateTrajectory(TargetPlayer);
		TargetPlayer = nullptr;
		if(!bFirstPoopThrown)
		{
			bFirstPoopThrown = true;
			Poop.bHomingPoop = true;
		}
		Poop = nullptr;

		UTundra_River_PoopMonkeyEventHandler::Trigger_OnThrowPoop(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbGetHit(ATundra_River_Snowball Snowball)
	{
		GetHit(Snowball);
	}

	void GetHit(ATundra_River_Snowball Snowball)
	{
		if(State == ETundraPoopMonkeyState::Hit)
			return;

		State = ETundraPoopMonkeyState::Hit;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		TraceSettings.UseLine();
		const FVector HorizontalForce = (ActorLocation - Snowball.ActorLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector) * 100;
		const FVector Start = ActorLocation + HorizontalForce + FVector::DownVector * 200;
		const FVector End = Start + FVector::DownVector * 2000;
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(Start, End);

		FVector LandLocation = End;
		if (GroundHit.bBlockingHit)
			LandLocation = GroundHit.ImpactPoint;

		float Gravity = 100;
		float Height = 100;
		FallTrajectory.LaunchLocation = ActorLocation;
		FallTrajectory.LandLocation = LandLocation;
		FallTrajectory.Gravity = FVector::DownVector * Gravity;
		FallTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(FallTrajectory.LaunchLocation, FallTrajectory.LandLocation, Gravity, Height);

		HitBySnowballTime = Time::GameTimeSeconds;
		FPoopMonkeyEventData Params;
		Params.Player = Snowball.OwningPlayer;
		UTundra_River_PoopMonkeyEventHandler::Trigger_OnHitBySnowball(this, Params);

		// Rotate monkey slightly towards the player
		FRotator WantedRotation = FRotator::MakeFromXZ((Snowball.OwningPlayer.ActorLocation - ActorLocation).GetSafeNormal(), FVector::UpVector);
		WantedRotation = (WantedRotation - ActorRotation).GetNormalized();
		AddActorLocalRotation(FRotator(0,
									   Math::Clamp(WantedRotation.Yaw, -30, 30),
									   0));
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, DetectionRange);
	}
#endif
};