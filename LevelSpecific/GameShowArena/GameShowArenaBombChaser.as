
class UGameShowArenaBombChaserChaseCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default CapabilityTags.Add(CapabilityTags::Movement);

	AGameShowArenaBombChaser BombChaser;

	UHazeMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	USweepingMovementData Movement;
	UMaterialInstanceDynamic TracksMaterial;

	FHazeAcceleratedFloat AccSpeed;
	bool bIsCollidingWithSpline;
	float TracksOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombChaser = Cast<AGameShowArenaBombChaser>(Owner);
		SyncedPositionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner, n"SyncedPosition");
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		TArray<ASplineActor> CollisionSplines;
		CollisionSplines.Add(BombChaser.CollisionSpline);
		MoveComp.ApplySplineCollision(CollisionSplines, this);

		TracksMaterial = BombChaser.Mesh.CreateDynamicMaterialInstance(0);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BombChaser.bShouldChase)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BombChaser.bShouldChase)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccSpeed.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector TargetLocation = BombChaser.ConnectedBomb.ActorLocation;
			if (BombChaser.bReturningToStart)
				TargetLocation = BombChaser.StartTransform.Location;

			FVector Dir = (TargetLocation - BombChaser.ActorLocation).GetSafeNormal2D();
			float RotationSpeed = 5;

			if (BombChaser.bReturningToStart)
			{
				if (BombChaser.ActorLocation.Dist2D(TargetLocation) < 1000)
					AccSpeed.AccelerateTo(0, 4.0, DeltaTime);

				if (Dir.DotProduct(BombChaser.ActorForwardVector) > 0.6)
					RotationSpeed = 0;
			}
			else
			{
				if (Dir.DotProduct(BombChaser.ActorForwardVector) < 0.5 || bIsCollidingWithSpline)
				{
					RotationSpeed = 3;
					AccSpeed.AccelerateTo(0, 0.3, DeltaTime);
				}
				else
				{
					AccSpeed.AccelerateTo(BombChaser.MaxSpeed, BombChaser.LerpDuration, DeltaTime);
				}
			}

			FRotator TargetRotation = FRotator::MakeFromX(Dir);

			Movement.SetRotation(Math::RInterpTo(BombChaser.ActorRotation, TargetRotation, DeltaTime, RotationSpeed));

			FVector DesiredMoveDelta = BombChaser.ActorForwardVector * AccSpeed.Value * DeltaTime;
			FVector NewLocation = BombChaser.ActorLocation + DesiredMoveDelta;
			FVector ClosestSplineWorldLocation = BombChaser.CollisionSpline.Spline.GetClosestSplinePositionToLineSegment(BombChaser.ActorLocation, NewLocation).WorldLocation;
			float DistToSpline = BombChaser.ActorLocation.DistSquared2D(ClosestSplineWorldLocation);
			float DistToNewLocation = NewLocation.DistSquared2D(BombChaser.ActorLocation);
			FVector DirToSpline = (ClosestSplineWorldLocation - BombChaser.ActorLocation).GetSafeNormal2D();
			if (DistToNewLocation > DistToSpline - (250 * 250) && DirToSpline.DotProduct(BombChaser.ActorForwardVector) > 0.5)
			{
				bIsCollidingWithSpline = true;
				BombChaser.bCanReachPlayer = false;
			}
			else
			{
				bIsCollidingWithSpline = false;
				BombChaser.bCanReachPlayer = true;
			}

			Movement.AddDelta(NewLocation - BombChaser.ActorLocation);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		TracksOffset += 100 * DeltaTime;
		TracksMaterial.SetScalarParameterValue(n"OffsetY", TracksOffset);

		MoveComp.ApplyMove(Movement);
	}
}

enum EGameShowArenaBombChaserMood
{
	Happy,
	Curious,
	Sad,
	VeryHappy
}

class UGameShowArenaBombChaserFaceControlCapability : UHazeCapability
{
	AGameShowArenaBombChaser BombChaser;
	float TimeWhenBombThrown;
	UMaterialInstanceDynamic FaceMaterial;
	int VeryHappyFaceEyes = 1;
	int VeryHappyFaceMouth = 1;

	int HappyFaceEyes = 15;
	int HappyFaceMouth = 15;

	int SadFaceEyes = 10;
	int SadFaceMouth = 25;

	int CuriousFaceEyes = 14;
	int CuriousFaceMouth = 14;

	EGameShowArenaBombChaserMood CurrentMood = EGameShowArenaBombChaserMood::Happy;

	bool bIsSad = false;
	bool bIsCurious = false;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombChaser = Cast<AGameShowArenaBombChaser>(Owner);
		BombChaser.ConnectedBomb.OnBombThrown.AddUFunction(this, n"OnBombThrown");
		FaceMaterial = BombChaser.Mesh.CreateDynamicMaterialInstance(BombChaser.Mesh.GetMaterialIndex(n"LED"));
		FaceMaterial.SetScalarParameterValue(n"CurrentFace", -1);
		FaceMaterial.SetScalarParameterValue(n"CurrentFaceEyes", HappyFaceEyes);
		FaceMaterial.SetScalarParameterValue(n"CurrentFaceMouth", HappyFaceMouth);
	}

	UFUNCTION()
	private void OnBombThrown(AHazePlayerCharacter Player)
	{
		TimeWhenBombThrown = Time::GameTimeSeconds;
		ChangeMood(EGameShowArenaBombChaserMood::Curious);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	void ChangeMood(EGameShowArenaBombChaserMood NewMood)
	{
		if (CurrentMood == NewMood)
			return;

		CurrentMood = NewMood;
 		int NewEyes = 0;
		int NewMouth = 0;
		switch (NewMood)
		{
			case EGameShowArenaBombChaserMood::Happy:
				NewEyes = HappyFaceEyes;
				NewMouth = HappyFaceMouth;
				break;
			case EGameShowArenaBombChaserMood::Curious:
				NewEyes = CuriousFaceEyes;
				NewMouth = CuriousFaceMouth;
				break;
			case EGameShowArenaBombChaserMood::Sad:
				NewEyes = SadFaceEyes;
				NewMouth = SadFaceMouth;
				break;
			case EGameShowArenaBombChaserMood::VeryHappy:
				NewEyes = VeryHappyFaceEyes;
				NewMouth = VeryHappyFaceMouth;
				break;
		}
		FaceMaterial.SetScalarParameterValue(n"CurrentFaceEyes", NewEyes);
		FaceMaterial.SetScalarParameterValue(n"CurrentFaceMouth", NewMouth);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		switch (CurrentMood)
		{
			case EGameShowArenaBombChaserMood::VeryHappy:
			case EGameShowArenaBombChaserMood::Happy:
			{
				if (!BombChaser.bCanReachPlayer)
					ChangeMood(EGameShowArenaBombChaserMood::Sad);
				else
				{
					float SquaredDist = BombChaser.GetSquaredHorizontalDistanceTo(BombChaser.ConnectedBomb);
					if (SquaredDist < 1e6)
						ChangeMood(EGameShowArenaBombChaserMood::VeryHappy);
					else
						ChangeMood(EGameShowArenaBombChaserMood::Happy);
				}
			}
			break;
			case EGameShowArenaBombChaserMood::Curious:
			{
				if (Time::GetGameTimeSince(TimeWhenBombThrown) > 1.5)
				{
					if (!BombChaser.bCanReachPlayer)
						ChangeMood(EGameShowArenaBombChaserMood::Sad);
					else
						ChangeMood(EGameShowArenaBombChaserMood::Happy);
				}
			}
			break;
			case EGameShowArenaBombChaserMood::Sad:
			{
				if (BombChaser.bCanReachPlayer)
					ChangeMood(EGameShowArenaBombChaserMood::Happy);
			}
			break;
		}
	}
}

class AGameShowArenaBombChaser : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent KillCollisionRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGameShowArenaBombChaserChaseCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UGameShowArenaBombChaserFaceControlCapability);

	UPROPERTY(DefaultComponent)
	USphereComponent MovementSphereComp;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "ForeArm")
	UBoxComponent KillBoxComp;
	default KillBoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default KillBoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	ASplineActor CollisionSpline;

	UPROPERTY()
	TSubclassOf<UDeathEffect> BombChaserDeathEffect;

	FTransform StartTransform;

	float CurrentSpeed = 500;
	float MaxSpeed = 1000;
	float LerpDuration = 2;

	float HitSphereRadius = 170;

	bool bShouldChase = false;
	bool bReturningToStart = false;
	bool bCanReachPlayer = true;

	float MinX;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaBomb ConnectedBomb;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTransform = ActorTransform;
		ConnectedBomb.OnStartHolding.AddUFunction(this, n"OnStartedHolding");
		ConnectedBomb.OnBombThrown.AddUFunction(this, n"OnBombThrown");
		ConnectedBomb.OnBombStartExploding.AddUFunction(this, n"OnBombExploded");
		KillBoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnKillBoxOverlap");
		MinX = ActorLocation.X - 2200;
	}

	UFUNCTION()
	private void OnStartedHolding(AHazePlayerCharacter Player)
	{
		bShouldChase = true;
	}

	UFUNCTION()
	private void OnBombThrown(AHazePlayerCharacter Player)
	{
	}

	UFUNCTION()
	private void OnBombExploded(AGameShowArenaBomb Bomb)
	{
		Timer::SetTimer(this, n"ResetToStartPosition", 3.25);
		Timer::SetTimer(this, n"StartReturnToStart", 1.5);
	}

	UFUNCTION()
	private void OnKillBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
						  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
						  const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		FPlayerDeathDamageParams DeathParams;
		DeathParams.ImpactDirection = (Player.ActorLocation - ActorLocation).GetSafeNormal();
		DeathParams.ForceScale = 5;
		Player.KillPlayer(DeathParams, BombChaserDeathEffect);
	}

	UFUNCTION()
	void ResetToStartPosition()
	{
		TeleportActor(StartTransform.Location, StartTransform.Rotator(), this);	
		bShouldChase = false;
		bReturningToStart = false;
	}

	UFUNCTION()
	private void StartReturnToStart()
	{
		bReturningToStart = true;
	}
};