enum EMeltdownBossPhaseTwoWormAttackTargetingType
{
	// Target a random player
	RandomPlayer,
	// Always target mio
	Mio,
	// Always target zoe
	Zoe,
}

struct FMeltdownBossPhaseTwoWormConfig
{
	UPROPERTY()
	float HorizontalSpeed = 2400.0;
	UPROPERTY()
	float DiveHorizontalSpeed = 800.0;
	UPROPERTY()
	float LockOnHorizontalSpeed = 1200.0;
	UPROPERTY()
	float HorizontalAcceleration = 1000.0;
	UPROPERTY()
	float TargetMaxHeight = 650.0;
	UPROPERTY()
	float TargetDiveHeight = 100.0;
	UPROPERTY()
	float HeightAcceleraton = 500.0;
	UPROPERTY()
	float DiveDistance = 800.0;
	UPROPERTY()
	float LockOnDistance = 400.0;
	UPROPERTY()
	float HeadKillRadius = 100.0;
	UPROPERTY()
	float ExplosionTriggerDistance = 1600.0;
	UPROPERTY()
	float ExplosionKillRadius = 400.0;
	UPROPERTY()
	float ExplosionInterval = 0.1;
	UPROPERTY()
	EMeltdownBossPhaseTwoWormAttackTargetingType TargetingType = EMeltdownBossPhaseTwoWormAttackTargetingType::RandomPlayer;
}

struct FMeltdownBossPhaseTwoTrailPosition
{
	FVector Location;
	FQuat Rotation;
}

class AMeltdownBossPhaseTwoWormAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent HeadMesh;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TailMesh;

	UPROPERTY()
	UStaticMesh BodyMesh;
	UPROPERTY()
	FVector SegmentScale = FVector::OneVector;
	UPROPERTY()
	float SegmentSpacing = 100;
	UPROPERTY()
	int BodySegmentCount = 30;

	UPROPERTY(EditInstanceOnly)
	ASplineActor EntrySpline;

	AHazePlayerCharacter TargetPlayer;
	FMeltdownBossPhaseTwoWormConfig Config;

	bool bLockedOn;
	bool bDiving;
	bool bSnapRotation;

	bool bExploding;
	int ExplosionProgress = 0;
	float ExplodeTimer = 0;

	bool bIsOnEntrySpline = false;
	FSplinePosition EntrySplinePosition;

	FVector LockOnDirection;
	FVector LockOnTargetLocation;
	float LockOnHeight;
	float GameTimeDiveStart;

	FVector HorizontalSpeed;
	float VerticalSpeed = 0.0;
	FTransform OriginalActorTransform;
	FQuat CurrentRotation;

	TArray<FMeltdownBossPhaseTwoTrailPosition> Trail;

	TArray<USceneComponent> Segments;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OriginalActorTransform = ActorTransform;

		Segments.Add(HeadMesh);
		for (int i = 0; i < BodySegmentCount; ++i)
		{
			auto Segment = UStaticMeshComponent::Create(this);
			Segment.SetStaticMesh(BodyMesh);
			Segment.SetRelativeScale3D(SegmentScale);
			Segment.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Segments.Add(Segment);
		}
		Segments.Add(TailMesh);
	}

	UFUNCTION(DevFunction)
	void Launch(FMeltdownBossPhaseTwoWormConfig LaunchConfig)
	{
		Config = LaunchConfig;
		VerticalSpeed = 0;
		bLockedOn = false;
		bDiving = false;
		bExploding = false;
		bSnapRotation = true;
		HorizontalSpeed = FVector::ZeroVector;
		ActorTransform = OriginalActorTransform;
		CurrentRotation = ActorQuat;
		ExplodeTimer = 0;
		ExplosionProgress = 0;

		for (auto Segment : Segments)
			Segment.RemoveComponentVisualsBlocker(this);

		if (EntrySpline != nullptr)
		{
			EntrySplinePosition = EntrySpline.Spline.GetSplinePositionAtSplineDistance(0.0);
			bIsOnEntrySpline = true;
		}
		else
		{
			bIsOnEntrySpline = false;
		}

		RemoveActorDisable(this);

		if (Config.TargetingType == EMeltdownBossPhaseTwoWormAttackTargetingType::RandomPlayer)
			TargetPlayer = Game::GetPlayer(EHazePlayer(Math::RandRange(0, 1)));
		else if (Config.TargetingType == EMeltdownBossPhaseTwoWormAttackTargetingType::Mio)
			TargetPlayer = Game::Mio;
		else if (Config.TargetingType == EMeltdownBossPhaseTwoWormAttackTargetingType::Zoe)
			TargetPlayer = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsOnEntrySpline)
		{
			const bool bCouldMove = EntrySplinePosition.Move(DeltaSeconds * Config.HorizontalSpeed);

			SetActorLocationAndRotation(EntrySplinePosition.WorldLocation, EntrySplinePosition.WorldRotation);
			UpdateTrail();

			HorizontalSpeed = EntrySplinePosition.WorldForwardVector * Config.HorizontalSpeed;

			if (!bCouldMove)
				bIsOnEntrySpline = false;

			return;
		}

		float Height = ActorLocation.Z;
		float MinHeight = -MAX_flt;
		float MaxHeight = MAX_flt;
		float TargetHeight;

		if (bLockedOn)
		{
			TargetHeight = LockOnHeight;
			MinHeight = LockOnHeight;
		}
		else if (bDiving)
		{
			TargetHeight = TargetPlayer.ActorLocation.Z + Config.TargetDiveHeight;
			MinHeight = TargetHeight;
		}
		else
		{
			if (EntrySpline != nullptr)
				TargetHeight = EntrySplinePosition.WorldLocation.Z;
			else
				TargetHeight = TargetPlayer.ActorLocation.Z + Config.TargetMaxHeight;
			MaxHeight = TargetHeight;
		}

		if (Math::IsNearlyEqual(TargetHeight, Height, 5.0))
		{
			VerticalSpeed = 0.0;
		}
		else if (TargetHeight > Height)
		{
			VerticalSpeed += Config.HeightAcceleraton * DeltaSeconds;
		}
		else
		{
			VerticalSpeed -= Config.HeightAcceleraton * DeltaSeconds;
		}

		Height += VerticalSpeed * DeltaSeconds;
		Height = Math::Clamp(Height, MinHeight, MaxHeight);
		VerticalSpeed = (Height - ActorLocation.Z) / DeltaSeconds;

		FVector MoveDirection;
		if (bLockedOn)
		{
			MoveDirection = LockOnDirection;
		}
		else
		{
			MoveDirection = (TargetPlayer.ActorLocation - ActorLocation);
			MoveDirection = MoveDirection.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		}

		float TargetHorizontalSpeed = Config.HorizontalSpeed;
		if (bLockedOn)
			TargetHorizontalSpeed = Config.LockOnHorizontalSpeed;
		else if (bDiving)
			TargetHorizontalSpeed = Config.DiveHorizontalSpeed;

		HorizontalSpeed = Math::VInterpConstantTo(
			HorizontalSpeed, MoveDirection * TargetHorizontalSpeed,
			DeltaSeconds, Config.HorizontalAcceleration);

		FVector NewLocation = ActorLocation;
		NewLocation += HorizontalSpeed * DeltaSeconds;
		NewLocation.Z = Height;

		FQuat TargetRotation = FQuat::MakeFromX(NewLocation - ActorLocation);
		FQuat NewRotation = Math::QInterpConstantTo(CurrentRotation, TargetRotation, DeltaSeconds, PI);

		if (bSnapRotation)
		{
			NewRotation = TargetRotation;
			bSnapRotation = false;
		}

		CurrentRotation = NewRotation;

		if (bDiving)
		{
			float DiveTimer = Time::GetGameTimeSince(GameTimeDiveStart);
			NewRotation = NewRotation * FQuat(FVector::ForwardVector,
				Math::Clamp(TWO_PI * DiveTimer / 2.0, 0, TWO_PI));
		}

		SetActorLocationAndRotation(NewLocation, NewRotation);
		UpdateTrail();

		PlayerHealth::KillPlayersInRadius(ActorLocation, Config.HeadKillRadius);

		float Distance = TargetPlayer.ActorLocation.Dist2D(ActorLocation);
		if (!bLockedOn && bDiving && Distance < Config.LockOnDistance
			&& Math::IsNearlyEqual(Height, TargetHeight, 150.0))
		{
			bLockedOn = true;
			LockOnDirection = MoveDirection;
			LockOnTargetLocation = TargetPlayer.ActorLocation;
			LockOnHeight = TargetPlayer.ActorLocation.Z + Config.TargetDiveHeight;
		}

		if (!bDiving && Distance < Config.DiveDistance)
		{
			bDiving = true;
			GameTimeDiveStart = Time::GameTimeSeconds;
		}

		if (bExploding)
		{
			ExplodeTimer += DeltaSeconds;
			if (ExplodeTimer >= Config.ExplosionInterval)
			{
				BP_ExplodeSegment(Segments[ExplosionProgress]);
				Segments[ExplosionProgress].AddComponentVisualsBlocker(this);
				PlayerHealth::KillPlayersInRadius(Segments[ExplosionProgress].WorldLocation, Config.ExplosionKillRadius);

				ExplodeTimer -= Config.ExplosionInterval;
				ExplosionProgress -= 1;

				if (ExplosionProgress < 0)
					AddActorDisable(this);
			}
		}

		if (!bExploding && Distance < Config.ExplosionTriggerDistance)
		{
			StartExploding();
		}
	}

	void UpdateTrail()
	{
		FMeltdownBossPhaseTwoTrailPosition NewPos;
		NewPos.Location = ActorLocation;
		NewPos.Rotation = ActorQuat;
		Trail.Add(NewPos);

		int UsedIndex = MAX_int32;
		for (int i = 0, Count = Segments.Num(); i < Count; ++i)
		{
			float Distance = SegmentSpacing * i;
			FVector Location = Trail[0].Location;
			FQuat Rotation = Trail[0].Rotation;

			for (int n = Trail.Num() - 2; n >= 0; --n)
			{
				UsedIndex = Math::Min(n, UsedIndex);

				float StepDist = Trail[n].Location.Distance(Trail[n+1].Location);
				if (StepDist > Distance)
				{
					Location = Math::Lerp(Trail[n+1].Location, Trail[n].Location, Distance / StepDist);
					Rotation = FQuat::Slerp(Trail[n+1].Rotation, Trail[n].Rotation, Distance / StepDist);
					break;
				}
				else
				{
					Distance -= StepDist;
					continue;
				}
			}

			Segments[i].SetWorldLocationAndRotation(Location, Rotation);
		}

		if (UsedIndex < Trail.Num())
		{
			for (int i = 0; i < UsedIndex; ++i)
				Trail.RemoveAt(0);
		}
	}

	void StartExploding()
	{
		bExploding = true;

		ExplosionProgress = Segments.Num() - 1;
		BP_ExplodeSegment(Segments[ExplosionProgress]);

		Segments[0].AddComponentVisualsBlocker(this);
		PlayerHealth::KillPlayersInRadius(Segments[ExplosionProgress].WorldLocation, Config.ExplosionKillRadius);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExplodeSegment(USceneComponent Component)
	{
	}
};