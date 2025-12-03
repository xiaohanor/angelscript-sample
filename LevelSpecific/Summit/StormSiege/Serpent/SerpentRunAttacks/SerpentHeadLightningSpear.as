UCLASS(Abstract)
class ASerpentHeadLightningSpear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent DamageSphereComp;
	default DamageSphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default DamageSphereComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default DamageSphereComp.SphereRadius = 500;

	AHazePlayerCharacter TargetPlayer;

	FVector StartPoint;
	FVector ControlPoint;
	FVector EndPoint;

	FVector PreviousVelocity;
	FVector InitialRightVector;

	FLinearColor DebugColor;

	float TimeWhenActivated = 0;

	const float MoveDuration = 3.5;
	const float MaxLifeTime = 10;
	const float HomingLocationUpdateSpeed = 8000;

	const float HomingDistanceThreshold = 5000;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectComp;

	default ActorTickEnabled = false;

	bool bHasStoppedHoming = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageSphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								 UPrimitiveComponent OtherComp, int OtherBodyIndex,
								 bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (OtherActor.IsA(AHazePlayerCharacter))
		{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
			Player.DamagePlayerHealth(0.1);
			DestroyActor();
		}
	}

	void InitializeAttack(FVector InStartPoint, FVector InControlPoint, AHazePlayerCharacter Target, FLinearColor InDebugColor = FLinearColor::Red)
	{
		StartPoint = InStartPoint;
		ControlPoint = InControlPoint;
		EndPoint = Target.ActorLocation;
		DebugColor = InDebugColor;
		TimeWhenActivated = Time::GameTimeSeconds;
		ActorTickEnabled = true;
		TargetPlayer = Target;
		SetActorRotation(FRotator::MakeFromX(Target.ActorLocation-StartPoint));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// TODO - DB - Break this into capabilities
		FVector NewLocation;
		float ActiveDuration = Time::GetGameTimeSince(TimeWhenActivated);

		//Stop homing towards player when we are close (to allow room to dodge), or when we have gone past the player
		float Dot = ActorForwardVector.DotProductNormalized(TargetPlayer.ActorLocation - ActorLocation);
		if (TargetPlayer.ActorLocation.Distance(ActorLocation) > HomingDistanceThreshold && Dot > 0.1)
			EndPoint = Math::VInterpConstantTo(EndPoint, TargetPlayer.ActorLocation, DeltaSeconds, HomingLocationUpdateSpeed);
		else
			bHasStoppedHoming = true;

		if (!bHasStoppedHoming)
		{
			float EasedAlpha = Math::CircularOut(0, 1, ActiveDuration / MoveDuration);
			NewLocation = BezierCurve::GetLocation_1CP(StartPoint, ControlPoint, EndPoint, EasedAlpha);
			PreviousVelocity = (NewLocation - ActorLocation) / DeltaSeconds;
		}
		else
		{
			NewLocation = ActorLocation + PreviousVelocity * DeltaSeconds;
		}

		SetActorLocation(NewLocation);

		if (ActiveDuration >= MaxLifeTime)
		{
			DestroyActor();
		}
	}
};